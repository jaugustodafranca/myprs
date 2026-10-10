# MyPRs

A macOS menu bar app and desktop widget that show your open GitHub pull requests:
failing CI, unanswered review threads and approvals at a glance.

See [docs/spec.md](docs/spec.md) for the design and [AGENTS.md](AGENTS.md) for contributor rules.

## Build

Requirements: macOS 14+, Xcode, [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
xcodegen generate
open MyPRs.xcodeproj
```

Run the tests (unsigned):

```bash
xcodebuild test -project MyPRs.xcodeproj -scheme MyPRs -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
```
