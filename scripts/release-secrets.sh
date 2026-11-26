#!/usr/bin/env bash
# Check secret scopes or stage the original signing credentials in the protected environment.
set +x
set -euo pipefail
umask 077
unset GH_DEBUG
repo=github.com/jaugustodafranca/myprs
endpoint=repos/jaugustodafranca/myprs/environments/release
project="$(cd "$(dirname "$0")/.." && pwd)/project.yml"
names=(
  DEVELOPER_ID_CERT_P12_BASE64 DEVELOPER_ID_CERT_PASSWORD
  APP_STORE_CONNECT_KEY_P8_BASE64 APP_STORE_CONNECT_KEY_ID APP_STORE_CONNECT_ISSUER_ID
  SPARKLE_PRIVATE_KEY
)

fail() { echo "$*" >&2; exit 1; }
list_names() { gh secret list --repo "$repo" "$@" --json name --jq '.[].name'; }
in_list() { grep -Fqx -- "$1" <<< "$2"; }

mode=${1:-check}
case "$mode" in
  check)
    scoped=$(list_names --env release)
    broad=$(list_names)
    status=0
    for name in "${names[@]}"; do
      if ! in_list "$name" "$scoped"; then echo "Missing from release: $name"; status=1; fi
      if in_list "$name" "$broad"; then echo "Present at repository scope: $name"; status=1; fi
    done
    if [[ $status == 0 ]]; then echo "All six credentials are scoped to release."; fi
    exit "$status"
    ;;
  stage|migrate) ;;
  *) fail "Usage: $0 check | {stage|migrate} <certificate.p12> <AuthKey_ID.p8> <Sparkle bin directory>" ;;
esac

[[ $# == 4 && -t 0 ]] || fail "Run in your terminal: $0 $mode <certificate.p12> <AuthKey_ID.p8> <Sparkle bin directory>"
p12=$2
p8=$3
generate_keys="$4/generate_keys"
[[ -r "$p12" && -r "$p8" && -x "$generate_keys" ]] || fail "Check the certificate, API key and Sparkle tool paths."
[[ $(basename "$p8") =~ ^AuthKey_([A-Z0-9]+)\.p8$ ]] || fail "Use the original AuthKey_ID.p8 filename."
key_id=${BASH_REMATCH[1]}

gh api --hostname github.com "$endpoint" | jq -e '
  any(.protection_rules[]?; .type == "required_reviewers" and (.reviewers | length) > 0)
  and .deployment_branch_policy.custom_branch_policies == true' >/dev/null || fail "Check release environment protections."
gh api --hostname github.com "$endpoint/deployment-branch-policies" | jq -e '
  .total_count == 1 and any(.branch_policies[]; .type == "tag" and .name == "v*")' >/dev/null || fail "Check the release tag policy."

repo_versions() { gh secret list --repo "$repo" --json name,updatedAt; }
before=$(repo_versions)

IFS= read -r -s -p "P12 export password: " password
echo
[[ -n "$password" ]] || fail "The signing certificate needs a password."
team=$(awk '$1 == "DEVELOPMENT_TEAM:" {print $2; exit}' "$project")
[[ -n "$team" ]] || fail "Missing expected Apple team in project.yml."
certificate=$(printf '%s\n' "$password" | /usr/bin/openssl pkcs12 -in "$p12" -passin stdin -clcerts -nokeys)
subject=$(printf '%s\n' "$certificate" | /usr/bin/openssl x509 -noout -subject -nameopt RFC2253)
[[ "$subject" == *"CN=Developer ID Application:"*"($team)"* ]] || fail "The certificate is not a Developer ID identity for MyPRs."
printf '%s\n' "$certificate" | /usr/bin/openssl x509 -noout -checkend 0 >/dev/null || fail "The certificate has expired."
cert_public=$(printf '%s\n' "$certificate" | /usr/bin/openssl x509 -pubkey -noout)
identity_public=$(printf '%s\n' "$password" | /usr/bin/openssl pkcs12 -in "$p12" -passin stdin -nocerts -nodes |
  /usr/bin/openssl pkey -pubout)
[[ -n "$cert_public" && "$cert_public" == "$identity_public" ]] || fail "The private key must match the signing certificate."

IFS= read -r -s -p "App Store Connect issuer ID: " issuer
echo
[[ -n "$issuer" ]] || fail "Missing App Store Connect issuer ID."
xcrun notarytool history --key "$p8" --key-id "$key_id" --issuer "$issuer" --output-format json |
  jq -e 'any(.history[]?; .status == "Accepted" and (.name | test("^MyPRs-[0-9].*\\.dmg$")))' >/dev/null ||
  fail "Could not confirm an accepted MyPRs DMG for these notarization credentials."

expected_key=$(awk '$1 == "SUPublicEDKey:" {print $2; exit}' "$project")
[[ -n "$expected_key" && "$("$generate_keys" -p)" == "$expected_key" ]] || fail "The Sparkle key does not match MyPRs."
gh run list --repo "$repo" --workflow release.yml --limit 100 --json status |
  jq -e 'all(.[]; .status == "completed")' >/dev/null || fail "Wait for the current release to finish before changing credentials."
scratch=$(mktemp -d)
trap 'rm -f "$scratch/sparkle-key"; rmdir "$scratch"' EXIT
trap 'exit 1' HUP INT TERM
"$generate_keys" -x "$scratch/sparkle-key" >/dev/null

put() { gh secret set "$1" --repo "$repo" --env release; }
base64 < "$p12" | tr -d '\n' | put DEVELOPER_ID_CERT_P12_BASE64
printf '%s' "$password" | put DEVELOPER_ID_CERT_PASSWORD
base64 < "$p8" | tr -d '\n' | put APP_STORE_CONNECT_KEY_P8_BASE64
printf '%s' "$key_id" | put APP_STORE_CONNECT_KEY_ID
printf '%s' "$issuer" | put APP_STORE_CONNECT_ISSUER_ID
put SPARKLE_PRIVATE_KEY < "$scratch/sparkle-key"
scoped=$(list_names --env release)
for name in "${names[@]}"; do
  in_list "$name" "$scoped" || fail "Upload incomplete. Check $name in the release environment."
done
echo "Staged and confirmed all six environment entries."
if [[ "$mode" == migrate ]]; then
  after=$(repo_versions)
  for name in "${names[@]}"; do
    filter='.[] | select(.name == $name) | .updatedAt'
    old=$(jq -r --arg name "$name" "$filter" <<< "$before")
    current=$(jq -r --arg name "$name" "$filter" <<< "$after")
    [[ "$old" == "$current" ]] || fail "$name changed during migration. Review it before retrying."
  done
  for name in "${names[@]}"; do
    if jq -e --arg name "$name" 'any(.[]; .name == $name)' <<< "$after" >/dev/null; then
      gh secret delete "$name" --repo "$repo"
    fi
  done
  "$0" check
fi
