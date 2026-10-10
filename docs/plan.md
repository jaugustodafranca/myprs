# MyPRs — implementation plan

Each task is one branch and one PR. Every PR: follows `AGENTS.md`, keeps CI
green, adds tests for any pure logic it introduces.

## 1. Scaffold (`feat/scaffold`) — first, everything else depends on it

- `project.yml` (XcodeGen): targets `MyPRs` (macOS app, 14.0, `LSUIElement`
  true, URL scheme `myprs`, not sandboxed, App Group entitlement),
  `MyPRsWidget` (widget extension, sandboxed, App Group, network off),
  `MyPRsTests` (unit tests, hosts nothing, compiles `Shared/` + needed app
  files). Team `688YYDN5Z4`, automatic signing, bundle ids from the spec.
  Sparkle as Swift package dependency of the app (2.x).
- `Shared/`: `PullRequest.swift`, `PullRequestSnapshot.swift`,
  `SnapshotStore.swift`, `AppConfig.swift` exactly as in the spec. Placeholder
  `gitHubClientID` and `authCallbackURL` values, filled later.
- `App/MyPRsApp.swift`: `MenuBarExtra` with the icon and a "Hello" view.
- `Widget/MyPRsWidgetBundle.swift`: widget that shows "MyPRs" text.
- `Tests/`: one test for `PullRequest.needsAttention` and a `SnapshotStore`
  round-trip using a temporary directory (make the container URL injectable
  only if needed for the test).
- `.github/workflows/ci.yml`: macOS runner, install XcodeGen, generate, test
  unsigned. A `worker` job is added in task 2.
- `.gitignore` (Xcode, DerivedData, `*.xcodeproj`, node_modules, `.wrangler`),
  `README.md` (what it is, how to build).

## 2. Auth worker (`feat/auth-worker`)

- `worker/` with `package.json`, `tsconfig.json`, `wrangler.toml`
  (name `myprs-auth`, var `GITHUB_CLIENT_ID`), `src/index.ts`, tests with
  vitest.
- `GET /callback?code&state`: exchange at
  `https://github.com/login/oauth/access_token` (JSON accept) with client id,
  secret (`GITHUB_CLIENT_SECRET` secret binding) and code. Redirect 302 to
  `myprs://auth?token=…&state=…` or `myprs://auth?error=…&state=…`. Missing
  code or state → `error=invalid_request`.
- Any other path → 404. Never log the token.
- Add `worker` job to CI: `npm ci`, `npx tsc --noEmit`, `npm test`.

## 3. GitHub client (`feat/github-client`)

- `App/GitHub/OpenPullRequestsQuery.swift` (the query string from the spec),
  `GitHubResponse.swift` (Decodable mirror of the response),
  `PullRequestMapper.swift` (response → `[PullRequest]` + login, applying the
  spec's definitions), `GitHubClient.swift` (`fetchOpenPullRequests(token:)
  async throws -> PullRequestSnapshot`, throws `GitHubError.unauthorized` on
  401, `.badResponse` otherwise).
- Tests with a JSON fixture covering: each check state, each review decision,
  resolved vs unresolved threads, last comment by me vs others, draft.

## 4. Widget (`feat/widget`)

- Timeline provider reads `SnapshotStore.load()`, one entry, refresh policy
  after 15 minutes.
- Medium (up to 3 rows) and large (up to 7 rows) layouts. Row: status dot
  (red failing, orange unanswered, green passing, gray otherwise), title,
  `repo#number`, small icons for review status and unanswered count. Attention
  first, then most recent.
- Row is a `Link` to the PR. Copy button uses `CopyLinkIntent` (App Intent,
  writes to `NSPasteboard`).
- Signed-out and "No open PRs 🎉" states. Footer with "Updated hh:mm".
- Sorting lives in `Shared/PullRequestSorting.swift` with a test (the app
  reuses it).

## 5. Updates and release pipeline (`feat/release`)

- `App/Updates/Updater.swift`: wraps `SPUStandardUpdaterController`, exposes
  `checkForUpdates()` and `canCheckForUpdates`. `CheckForUpdatesButton` view.
- `Info.plist` keys via `project.yml`: `SUFeedURL`, `SUPublicEDKey`
  (placeholder until the key is generated), `SUEnableAutomaticChecks` true.
- `.github/workflows/release.yml` on tag `v*`: import Developer ID cert from
  secrets, `xcodebuild archive` + export (Developer ID), `notarytool submit
  --wait` with App Store Connect API key, `stapler staple`, DMG via `hdiutil`,
  Sparkle `sign_update`, generate `appcast.xml` (single latest item), create
  GitHub Release with DMG + appcast. Version from the tag, build number from
  the run number.
- `scripts/` only if a step is too long to read inline in the workflow.
- `docs/release.md`: required secrets and how to cut a release.

## 6. App core (`feat/app-core`) — after 3 and 5

- `App/Auth/TokenStore.swift` (Keychain), `App/Auth/LoginFlow.swift`
  (`ASWebAuthenticationSession`, random state, `LoginCallback` parser in its
  own file with tests).
- `App/Monitor/PullRequestMonitor.swift` (`@Observable @MainActor`): sign
  in/out, timer, `refresh()`, error state, saves snapshot, reloads widgets,
  handles 401.
- `App/Monitor/ChangeDetector.swift` (pure, tested) and
  `App/Monitor/Notifier.swift` (UserNotifications).
- `App/UI/`: `MenuContentView`, `PullRequestRow`, `SignedOutView`,
  `SettingsSection` (interval, launch at login via `SMAppService`, check for
  updates, sign out). Icon tint per spec.

## 7. Wire-up (done by the architect)

- Deploy worker, create the OAuth App, fill `AppConfig`, Sparkle key, GitHub
  secrets, local signed build, end-to-end test.
