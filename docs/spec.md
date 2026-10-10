# MyPRs — design spec

Date: 2026-10-10

## Goal

See at a glance, without opening the browser, every open pull request you
authored on GitHub: is CI broken, is someone waiting for your answer, is it
approved. Open or copy a PR link in one click.

## Product

- macOS 14+ menu bar app (no Dock icon) plus a desktop widget (WidgetKit).
- Sign in with GitHub by redirect: click "Sign in", authorize on github.com,
  come back signed in. No codes to copy.
- Lists all open PRs authored by the signed-in user, across every repo the
  token can read. Drafts are shown with a "Draft" label.
- Per PR: repository, number, title, CI status, review status, number of
  unanswered review threads.
- Refreshes on a timer (default 2 minutes, configurable 1/2/5/10/15) and on
  demand.
- Native notification when a PR's CI goes from not failing to failing, and when
  its unanswered thread count goes up.
- Notifies the user when a new version is available and installs it (Sparkle).

Out of scope for v1: PRs awaiting my review, GitLab, multiple accounts, repo
filters.

### Definitions

- **CI status** — the `statusCheckRollup` of the PR's last commit:
  `SUCCESS` → passing, `FAILURE`/`ERROR` → failing, `PENDING`/`EXPECTED` →
  running, missing → none.
- **Review status** — `reviewDecision`: `APPROVED` → approved,
  `CHANGES_REQUESTED` → changesRequested, anything else → waiting.
- **Unanswered thread** — a review thread that is not resolved and whose last
  comment was not written by the signed-in user.
- **Needs attention** — a PR with failing CI or at least one unanswered thread.

### Menu bar

- Icon: `arrow.triangle.pull`. Tinted red when any PR has failing CI, orange
  when any PR has unanswered threads, default otherwise.
- Click opens a window-style panel with the PR list (attention first, then most
  recently updated), each row with "Open" and "Copy link", plus "Refresh now",
  last update time, and a settings section: refresh interval, launch at login,
  check for updates, sign out.
- Signed out: a single "Sign in with GitHub" button.

### Widget

- Medium and large sizes. Shows the same list from the shared cache.
- Tapping a row opens the PR. Each row has a copy-link button (App Intent).
- Signed out / empty states with a short message.

## Architecture

```
┌──────────────── Mac ────────────────┐         ┌──────── Cloudflare ────────┐
│ MyPRs.app (menu bar)                │  login  │ myprs-auth Worker          │
│  LoginFlow ── default browser ──────┼────────▶│ GET /callback              │
│  TokenStore (Keychain)              │◀────────┼ code → token, HTML page    │
│  PullRequestMonitor (timer)         │ myprs:// │ opens myprs://auth?token…  │
│   └ GitHubClient ──── GraphQL ──────┼──▶ api.github.com                    │
│   └ ChangeDetector → Notifier       │         └────────────────────────────┘
│   └ SnapshotStore.shared.save ─┐           │
│ MyPRsWidget.appex       │ App Group │
│   └ SnapshotStore.shared.load ◀┘           │
└─────────────────────────────────────┘
```

- **Worker** holds the OAuth client secret. It only exchanges the authorization
  code for a token and answers with a small HTML page that navigates to
  `myprs://auth?token=…&state=…` (or `?error=…&state=…`), with an "Open MyPRs"
  link as a manual fallback. It stores nothing.
- **Login** happens in the user's default browser: the app opens the GitHub
  authorize URL with `NSWorkspace`, then waits for the `myprs://auth` callback,
  delivered to `AppDelegate.application(_:open:)` and routed to `LoginFlow`.
  Starting a new sign-in cancels a pending one; callbacks with no pending
  sign-in are ignored; the state must match.
- **App** talks to GitHub directly with the token. It is the only process that
  holds the token and does network calls.
- **Widget** never calls the network. It reads `snapshot.json` from the App
  Group container. The app calls `WidgetCenter.shared.reloadAllTimelines()`
  after each save.

### Identifiers

| Thing | Value |
|---|---|
| Bundle id (app) | `com.zaintech.myprs` |
| Bundle id (widget) | `com.zaintech.myprs.widget` |
| App Group | `688YYDN5Z4.com.zaintech.myprs` |
| Team | Zaintech LTDA, `688YYDN5Z4`, Developer ID |
| URL scheme | `myprs` |
| Worker | `myprs-auth`, served at `https://myprs-auth.zaintech.com.br` |
| OAuth scope | `repo` (needed to read private repos) |
| Update feed | `https://github.com/jaugustodafranca/myprs/releases/latest/download/appcast.xml` |

The app is not sandboxed (Developer ID distribution, needed for Sparkle without
extra XPC setup). The widget extension is sandboxed, as WidgetKit requires.

### Shared types (`Shared/`, compiled into app, widget and tests)

```swift
struct PullRequest: Codable, Hashable, Identifiable {
    let id: String            // GraphQL node id
    let number: Int
    let title: String
    let url: URL
    let repository: String    // "owner/name"
    let isDraft: Bool
    let checks: CheckStatus
    let review: ReviewStatus
    let unansweredThreads: Int
    let updatedAt: Date
    var needsAttention: Bool { checks == .failing || unansweredThreads > 0 }
}
enum CheckStatus: String, Codable { case passing, failing, running, none }
enum ReviewStatus: String, Codable { case approved, changesRequested, waiting }

struct PullRequestSnapshot: Codable {
    let login: String
    let pullRequests: [PullRequest]
    let fetchedAt: Date
}

struct SnapshotStore {
    static let shared: SnapshotStore   // App Group container
    init(directory: URL)               // tests pass a temporary directory
    func load() -> PullRequestSnapshot?
    func save(_ snapshot: PullRequestSnapshot)
    func clear()
}

enum AppConfig { appGroupID, urlScheme, gitHubClientID, authCallbackURL, ... }
```

### GitHub query

One GraphQL request per refresh:

```graphql
query {
  viewer { login }
  search(query: "is:pr is:open author:@me archived:false", type: ISSUE, first: 50) {
    nodes {
      ... on PullRequest {
        id number title url isDraft updatedAt reviewDecision
        repository { nameWithOwner }
        commits(last: 1) { nodes { commit { statusCheckRollup { state } } } }
        reviewThreads(first: 100) {
          nodes { isResolved comments(last: 1) { nodes { author { login } } } }
        }
      }
    }
  }
}
```

### Errors

- HTTP 401 from GitHub → token is revoked: delete it, clear the snapshot, show
  the signed-out state.
- Network or other errors → keep the last snapshot, show a small "Couldn't
  refresh" line with the time of the last success. Retry on the next tick.
- Login: state mismatch, user cancel, or `error=` in callback → stay signed out
  and show the reason.

## Code style

See `AGENTS.md`. Readability and simplicity first.

## Quality and delivery

- **CI** (`.github/workflows/ci.yml`) on every PR and push to `main`: generate
  the Xcode project with XcodeGen, build and run unit tests (unsigned); worker
  type check and tests. PRs merge only when CI is green.
- **Release** (`.github/workflows/release.yml`) on tag `v*`: build, sign with
  Developer ID, notarize, staple, package a DMG, sign it for Sparkle, publish a
  GitHub Release with the DMG and `appcast.xml`.
- Unit tests cover pure logic: GraphQL response mapping, change detection,
  login callback parsing, worker handler.
