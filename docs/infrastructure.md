# Infrastructure

What MyPRs depends on outside this repository, who owns it and how to change
it. Secrets appear here by name only. Their values live in GitHub Actions
secrets, in the Worker's secret store or in the maintainer's keychain, never in
this repository, in the app binary or in a PR.

## Map

| Piece | Where | Account |
|---|---|---|
| Source, CI, releases, update feed | GitHub repository `jaugustodafranca/myprs` | maintainer |
| OAuth App "MyPRs" | GitHub > Settings > Developer settings > OAuth Apps | maintainer |
| Auth worker `myprs-auth` | Cloudflare Workers, zone `zaintech.com.br` | maintainer |
| Code signing and notarization | Apple Developer team `688YYDN5Z4` (Zaintech LTDA) | Zaintech |

## GitHub OAuth App

- Authorization callback URL: `https://myprs-auth.zaintech.com.br/callback`.
- Scopes the app asks for: `repo read:org` (set in `LoginFlow`).
- The client id is public and committed (`AppConfig.gitHubClientID`,
  `worker/wrangler.toml`). The client secret exists only as the Worker secret
  `GITHUB_CLIENT_SECRET`. The app never has it, which is why the token
  exchange goes through the Worker.
- Organizations that restrict third-party OAuth access must approve the app
  once. Until they do, their PRs are missing and the panel shows a banner
  linking to `AppConfig.organizationAccessURL`.
- To rotate the secret: generate a new one on the OAuth App page, then run
  `npx wrangler secret put GITHUB_CLIENT_SECRET` in `worker/`. Tokens already
  issued to users keep working.

## Cloudflare Worker

The code is `worker/` (TypeScript, plain `fetch` handler, vitest). It serves
three routes on `https://myprs-auth.zaintech.com.br`:

| Route | Role |
|---|---|
| `GET /callback` | GitHub redirects here; a small page forwards `code` and `state` (or `error` and `state`) to `myprs://auth`, so no token passes through a URL |
| `POST /token` | Exchanges `code` plus the PKCE `code_verifier` for a token, adding the client secret |
| `POST /revoke` | Revokes a token on sign-out |

Deploy from a machine logged into the maintainer's Cloudflare account:

```bash
cd worker && npm ci && npm test && npx tsc --noEmit
npx wrangler login
npx wrangler deploy
```

`wrangler.toml` routes the custom domain and sets `workers_dev = false`, so
the Worker is not reachable through a `*.workers.dev` URL.

Rate limiting is a zone rule, not code. In the zone's rate-limiting ruleset
(dashboard: Security > WAF > Rate limiting rules) the rule "MyPRs auth worker:
limit sign-in endpoints per IP" blocks an IP for 10 seconds once it sends more
than 10 requests in 10 seconds to `/callback`, `/token` or `/revoke` on
`myprs-auth.zaintech.com.br`. Change it there or through the Cloudflare API
(`rulesets/phases/http_ratelimit/entrypoint`).

Security headers (`cache-control: no-store`, HSTS, `nosniff`) and the
Content-Security-Policy are set in code. The callback page's inline script is
allowed by hash; a test fails if the script and `PAGE_SCRIPT_HASH` drift apart.

## GitHub repository

- Secret scanning and push protection: on.
- Dependabot: alerts and security updates on; version updates come from
  `.github/dependabot.yml`.
- Environment `release`: requires approval from the owner, and its deployment
  policy only allows tags matching `v*`. The release job does not start, and
  no secret is read, before the approval.
- Tag ruleset "Protect release tags": creating, updating and deleting `v*`
  tags is blocked for everyone except repository admins.
- Actions secrets (repository level): the six listed in `docs/release.md`.

## Apple

- Team `688YYDN5Z4`. Bundle ids `com.zaintech.myprs` (app),
  `com.zaintech.myprs.widget` (widget), `com.zaintech.myprs.tests` (tests).
  App Group `688YYDN5Z4.com.zaintech.myprs`. URL scheme `myprs`.
- Release builds are signed with a "Developer ID Application" certificate and
  notarized with an App Store Connect API key. `docs/release.md` explains how
  to create both and which secrets hold them.
- No provisioning profile is used. That is why the token lives in the login
  keychain rather than the data-protection keychain (see `docs/decisions.md`).

## Sparkle

- Feed: `https://github.com/jaugustodafranca/myprs/releases/latest/download/appcast.xml`,
  published by the release workflow and signed with EdDSA.
- Public key: `SUPublicEDKey` in `project.yml`. Private key: the
  `SPARKLE_PRIVATE_KEY` secret and the maintainer's login keychain, where
  `generate_keys` stored it.
- Installed apps only accept updates signed with the key in their own
  `Info.plist`, so the pair is not rotated casually. If it must be, ship one
  release signed with the old key that carries the new public key, then sign
  the next releases with the new key.

## If a secret leaks

| Secret | Action |
|---|---|
| OAuth client secret | Rotate it on the OAuth App page and update the Worker secret |
| `SPARKLE_PRIVATE_KEY` | Rotate the pair as above and check that nobody published a release |
| Developer ID certificate | Revoke it in the developer portal, create a new one, update the two certificate secrets |
| App Store Connect API key | Revoke it in App Store Connect, create a new one, update the three key secrets |
| A user's token | Sign out in the app (calls `/revoke`) or revoke the app under GitHub > Settings > Applications |
