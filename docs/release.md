# Releasing MyPRs

## Cut a release

```bash
git tag v0.1.0
git push origin v0.1.0
```

The `Release` workflow builds, signs, notarizes and staples the app, packages
`MyPRs-0.1.0.dmg`, signs it for Sparkle, and publishes a GitHub Release with the
DMG and `appcast.xml`. Installed apps find updates through
`releases/latest/download/appcast.xml`.

The marketing version comes from the tag (without the `v`); the build number is
the workflow run number.

## Secrets

Add these under GitHub repo Settings > Secrets and variables > Actions.

| Secret | What it is |
|---|---|
| `DEVELOPER_ID_CERT_P12_BASE64` | Developer ID Application certificate with private key, as base64 |
| `DEVELOPER_ID_CERT_PASSWORD` | Password chosen when exporting the .p12 |
| `APP_STORE_CONNECT_KEY_ID` | Key ID of the App Store Connect API key |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID shown on the API keys page |
| `APP_STORE_CONNECT_KEY_P8_BASE64` | The downloaded `AuthKey_XXXX.p8`, as base64 |
| `SPARKLE_PRIVATE_KEY` | Sparkle EdDSA private key |

### Developer ID certificate

1. In Xcode > Settings > Accounts > Manage Certificates, create a
   "Developer ID Application" certificate (or create it at developer.apple.com).
2. Open Keychain Access > My Certificates, right-click the certificate (expand it
   to be sure the private key is included) > Export, format `.p12`, set a password.
3. `base64 -i DeveloperID.p12 | pbcopy` and paste as `DEVELOPER_ID_CERT_P12_BASE64`.

### App Store Connect API key (notarization)

1. appstoreconnect.apple.com > Users and Access > Integrations > App Store Connect API.
2. Generate a key with the Developer role. Note the Key ID and the Issuer ID.
3. Download `AuthKey_XXXX.p8` (only possible once).
4. `base64 -i AuthKey_XXXX.p8 | pbcopy` and paste as `APP_STORE_CONNECT_KEY_P8_BASE64`.

### Sparkle keys

Download the Sparkle release tarball matching `SPARKLE_VERSION` in the workflow
and run:

```bash
./bin/generate_keys            # stores the private key in your login keychain, prints the public key
./bin/generate_keys -x sparkle_private_key   # exports the private key to a file
```

- Put the printed public key in `project.yml` as `SUPublicEDKey` (replacing
  `REPLACE_WITH_SPARKLE_PUBLIC_KEY`).
- Put the contents of `sparkle_private_key` in `SPARKLE_PRIVATE_KEY`, then delete the file.

## Signing notes

- The release build uses manual signing with the Developer ID certificate and no
  provisioning profile. The only entitlement needing a team-prefixed identifier is
  the App Group (`688YYDN5Z4.com.zaintech.myprs`), which macOS accepts without a
  profile for Developer ID apps. If `xcodebuild archive` or export complains about
  a missing profile, create a Developer ID provisioning profile for the app and
  the widget in the developer portal and install it in the workflow.
- Sparkle's nested helpers are re-signed by Xcode during export.
