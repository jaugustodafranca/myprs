<p align="center">
  <img src="assets/logo.svg" width="128" alt="MyPRs logo">
</p>

<h1 align="center">MyPRs</h1>

<p align="center">
  Your open GitHub pull requests, one glance away in the macOS menu bar.
</p>

<p align="center">
  <a href="https://github.com/jaugustodafranca/myprs/actions/workflows/ci.yml"><img src="https://github.com/jaugustodafranca/myprs/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://github.com/jaugustodafranca/myprs/releases/latest"><img src="https://img.shields.io/github/v/release/jaugustodafranca/myprs" alt="Latest release"></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-blue" alt="macOS 14+">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green" alt="MIT license"></a>
</p>

## What it does

- Lists your open pull requests in the menu bar and in a desktop widget
- Shows CI status for each PR: passing, running or failing
- Counts unanswered review threads so nothing waits on you unnoticed
- Shows review status: approved, changes requested or pending
- Opens a PR or copies its link in one click
- Updates itself with Sparkle

## Screenshots

Screenshots are coming soon.

<!--
<p align="center">
  <img src="assets/screenshots/menu-bar.png" width="420" alt="Menu bar">
  <img src="assets/screenshots/widget.png" width="420" alt="Desktop widget">
</p>
-->

## Install

1. Download the latest `.dmg` from [GitHub Releases](https://github.com/jaugustodafranca/myprs/releases/latest).
2. Drag MyPRs to Applications and open it.

Requires macOS 14 or later. After the first install, updates arrive automatically through Sparkle.

## Sign in & privacy

- Sign in with GitHub through a standard browser redirect.
- Your token is stored in the macOS Keychain.
- The app talks only to `api.github.com`.
- A tiny Cloudflare Worker exchanges the OAuth code for a token and stores nothing.
- Organizations that restrict third-party apps need to approve MyPRs once.

## Build from source

Requirements: macOS 14+, Xcode, [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
xcodegen generate
open MyPRs.xcodeproj
```

Run the tests:

```bash
xcodebuild test -project MyPRs.xcodeproj -scheme MyPRs -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
```

Worker:

```bash
cd worker && npm ci && npm test && npx tsc --noEmit
```

## Project layout

```
App/        Menu bar app
Widget/     Widget extension
Shared/     Types shared by app, widget and tests
Tests/      Unit tests
worker/     Cloudflare Worker for the OAuth code exchange
docs/       Specification
assets/     Logo and screenshots
```

See [docs/spec.md](docs/spec.md) for the design and [AGENTS.md](AGENTS.md) for contributor rules.

## License

[MIT](LICENSE)
