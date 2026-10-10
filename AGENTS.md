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
project.yml          XcodeGen definition (the .xcodeproj is generated, not committed)
Shared/              Types used by app, widget and tests
App/                 Menu bar app
Widget/              Widget extension
Tests/               Unit tests (Swift Testing)
worker/              Cloudflare Worker for the OAuth code exchange
scripts/             Release helpers
.github/workflows/   CI and release
```

## Commands

```bash
xcodegen generate
xcodebuild test -project MyPRs.xcodeproj -scheme MyPRs -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
cd worker && npm ci && npm test && npx tsc --noEmit
```

## Workflow

- One branch and one PR per task. Branch name `feat/<short-name>`.
- Conventional commit messages (`feat:`, `fix:`, `chore:`, `ci:`, `docs:`).
- CI must be green before merging. Squash merge.
