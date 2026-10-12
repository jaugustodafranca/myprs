#!/usr/bin/env bash
# Installs a pinned XcodeGen release (checksum verified) and puts it on PATH for later CI steps.
# To bump: change the version and the SHA-256 of the xcodegen.zip release asset together.
set -euo pipefail

version="2.46.0"
sha256="4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806"

dir="${RUNNER_TEMP:?RUNNER_TEMP is required}/xcodegen-download"
mkdir -p "$dir"
curl -fsSL -o "$dir/xcodegen.zip" "https://github.com/yonaskolb/XcodeGen/releases/download/${version}/xcodegen.zip"
echo "${sha256}  $dir/xcodegen.zip" | shasum -a 256 -c -
unzip -q "$dir/xcodegen.zip" -d "$dir"
echo "$dir/xcodegen/bin" >> "${GITHUB_PATH:?GITHUB_PATH is required}"
