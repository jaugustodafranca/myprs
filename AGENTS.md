# MyPRs — rules for contributors and agents

Read `docs/spec.md` before changing anything. It is the source of truth for
behaviour, identifiers and shared types. `docs/decisions.md` says why things
are the way they are; `docs/infrastructure.md` covers what lives outside the
repository.

## Code style

The code must be easy for a human to read. Prefer simple over clever.

- Names explain intent. A reader should understand a function from its name
  and signature without a comment.
- Small files with one job each. Small functions. Early returns over nesting.
- No comments that repeat the code. A short comment is fine only for a
  non-obvious *why* (an API quirk, a platform limitation).
- No speculative abstractions: no protocols with a single implementation unless
  a test needs to fake it, no generic helpers "for later", no configuration
  nobody asked for.
- Swift: SwiftUI, `async/await`, `@Observable`. No third-party dependencies
  except Sparkle. Keep views dumb; logic lives in plain types that tests can
  call.
- TypeScript (worker): no framework, plain `fetch` handler.

## Layout

```
CLAUDE.md                    Points Claude Code at this file
project.yml                  XcodeGen definition (the .xcodeproj is generated, not committed)
MyPRs/                       Menu bar app target
  App/                       Entry point and app delegate
  Features/                  One folder per screen: AIReview, MenuBar, OpenPullRequests,
                             RecentPullRequests, Review, Settings, SignIn, Updates
  Services/                  GitHub (client, queries, mappers), Monitoring (polling, change detection, notifications)
  Components/                Reusable app-only views and helpers
  Resources/                 Asset catalog; generated Info.plist and entitlements
MyPRsWidget/                 Widget extension target
  Timeline/                  Timeline provider, entry and widget bundle
  Views/                     Widget views
  Intents/                   App Intents (copy link, copy branch)
MyPRsTests/                  App tests (Swift Testing, hosted by the app)
Packages/MyPRsKit/           Local Swift package shared by app and widget
  Sources/MyPRsKit/          Models, Logic, Storage, DesignSystem (only what the widget also uses)
  Tests/MyPRsKitTests/       Package tests
worker/                      Cloudflare Worker for the OAuth code exchange
scripts/                     Release helpers; preview/ renders screens to PNG for prototypes
docs/                        Specification, release guide, infrastructure, decision log
assets/                      Logo and README media
.github/workflows/           CI and release
```

Naming rules:

- Swift code folders use PascalCase and match the target or module name
  (`MyPRs`, `MyPRsWidget`, `MyPRsTests`, `MyPRsKit`).
- Repo infrastructure folders (`docs`, `scripts`, `worker`, `assets`, `.github`)
  are lowercase.
- One primary type per file, and the file is named after the type.
- A feature folder groups a screen's views and its view-specific logic.
- Code used by both the app and the widget lives in `MyPRsKit`. Code only the
  app uses stays in `MyPRs`. A type in `MyPRsKit` is `public` only if the app or
  widget needs it.

## Commands

```bash
xcodegen generate
xcodebuild test -project MyPRs.xcodeproj -scheme MyPRs -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
swift test --package-path Packages/MyPRsKit   # package tests only, no Xcode project needed
cd worker && npm ci && npm test && npx tsc --noEmit
```

## Local development

Tests need no signing. Running the app itself, with the widget and the
`myprs://` login callback, needs a signed build installed in `/Applications`:
WidgetKit only discovers widgets of apps installed there, and a build left in
DerivedData registers a second handler for the URL scheme. The maintainer's
flow, which needs the Developer ID certificate in the login keychain:

```bash
xcodegen generate
xcodebuild -project MyPRs.xcodeproj -scheme MyPRs -configuration Release -destination 'platform=macOS' -derivedDataPath build \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="Developer ID Application" DEVELOPMENT_TEAM=688YYDN5Z4 \
  PROVISIONING_PROFILE_SPECIFIER="" OTHER_CODE_SIGN_FLAGS="--timestamp" build
pkill -x MyPRs; rm -rf /Applications/MyPRs.app && cp -R build/Build/Products/Release/MyPRs.app /Applications/
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/MyPRs.app
killall chronod   # drops WidgetKit's cached gallery so the new widget shows up
open /Applications/MyPRs.app
```

Rules for agents:

- Do not launch the app, open Xcode, or run anything that puts a macOS prompt
  (keychain, notifications, Sparkle) on the user's screen. Ask the user to test
  a build and say what to look at.
- `xcodebuild test` starts the app as the test host. When
  `AppEnvironment.isRunningTests` is true the launcher runs a bare
  `TestHostApp` instead of `MyPRsApp`, so nothing touches the Keychain, App
  Group, notifications, Sparkle or widgets; keep it that way.
- To show how a screen looks, render it with `scripts/preview` (see its README)
  and send the PNG instead of building and launching the app.

## Data that never enters the repository

- No real company data: no real organization or repository names other than
  this one, no colleagues' logins, no internal ticket keys, no company-specific
  prompts. This covers tests, sample data, docs, screenshots, commit messages
  and PR descriptions. Use fictional names such as `acme/storefront` and
  `jdoe`. The maintainer's own login and this repository are fine.
- No secrets, and no identifiers that unlock anything: tokens, keys,
  certificate material, Cloudflare or App Store Connect ids. Refer to them by
  name (`docs/infrastructure.md`).
- When delegating to a subagent, put both rules in its brief.

## Workflow

- One branch and one PR per task. Branch name `<type>/<short-name>` with the
  commit type (`feat`, `fix`, `chore`, `docs`).
- Conventional commit messages (`feat:`, `fix:`, `chore:`, `ci:`, `docs:`).
- CI must be green before merging. Squash merge.
