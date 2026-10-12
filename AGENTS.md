# MyPRs — rules for contributors and agents

Read `docs/spec.md` before changing anything. It is the source of truth for
behaviour, identifiers and shared types.

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
project.yml                  XcodeGen definition (the .xcodeproj is generated, not committed)
MyPRs/                       Menu bar app target
  App/                       Entry point and app delegate
  Features/                  One folder per screen: MenuBar, OpenPullRequests,
                             RecentPullRequests, Settings, SignIn, Updates
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
scripts/                     Release helpers
docs/                        Specification and release guide
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

## Workflow

- One branch and one PR per task. Branch name `feat/<short-name>`.
- Conventional commit messages (`feat:`, `fix:`, `chore:`, `ci:`, `docs:`).
- CI must be green before merging. Squash merge.
