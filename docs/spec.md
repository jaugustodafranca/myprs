# MyPRs — design spec

Date: 2026-10-10 (Review tab: 2026-10-14)

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
- Refreshes on a timer (default 30 minutes, configurable 5/10/15/30/60) and on
  demand.
- Native notification when a PR's CI goes from not failing to failing, and when
  its unanswered thread count goes up.
- A Review tab listing other people's PRs found by the user's saved GitHub
  searches, with optional notifications for new ones.
- Notifies the user when a new version is available and installs it (Sparkle).

Out of scope for v1: GitLab, multiple accounts.

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
- Click opens a window-style panel: a header with the Open · Recent · Review
  tabs (⌘1 / ⌘2 / ⌘3 while the panel is open), the last update time, "Refresh
  now" and a gear that opens Settings inside the panel, then the list. Open lists the
  PRs (newest creation first, with related PRs kept together), each row with "Open" and
  "Copy link". ⌘Q quits and ⌘, opens Settings while the panel is open.
- Signed out: a single "Sign in with GitHub" button.

### Related pull requests and order

- Open, Review, Recent and list widgets infer dependencies from branches; no
  GitHub stack metadata or title convention is required. A child's base repository
  and branch must exactly identify another listed PR's head repository and branch
  (repository names are case-insensitive, branch names are case-sensitive).
- Connected PRs appear in a subtle outlined box: repository, root target branch,
  count, and aligned rows with `Base: #<parent>` when a parent is known. Independent
  PRs remain plain rows interleaved with boxes. App boxes can be collapsed.
  Box headers put repository and target on the first line, counts on a secondary
  line. Dividers separate adjacent plain rows and expanded box contents only;
  spacing and the box outline separate groups from their neighbors.
- Rows within a box are newest-created first. Boxes and independent rows are ordered
  by their newest creation date, with stable ID tie-breaking. Alerts do not reorder
  the list. Keeping a box together takes precedence over globally interleaving all
  of its individual rows by date.
- Review groups only within each existing saved-search section after deduplication.
  Recent groups the pages loaded so far; its load-more trigger stays outside boxes.
- Missing repository identity, missing parents, ambiguous branch matches and cycles
  must not produce guessed relationships. Historical PRs can only be linked from
  the branch information GitHub still exposes; deleted forks and retargeted bases
  may prevent a group from being reconstructed.

### Recent tab

- Recent lists the user's closed and merged PRs (newest creation first) so an
  old PR's link or branch is one click away. Rows show a "Merged" or "Closed"
  badge, `head → base`, `repo#number · merged 3d ago`, diff size and file
  count, with the same open / copy branch / copy link actions as Open rows.
- The first page is refreshed with the app so the widget can show Recent without opening the tab. The panel loads additional pages, 20 at a time. Scrolling to the
  footer fetches the next page until `hasNextPage` is false. While any group is
  collapsed, the footer offers manual "Load more" to avoid eagerly fetching history
  merely because the collapsed list is short. Reopening the
  tab after more than 10 minutes fetches the first page again.
- A failed page shows "Couldn't load. Retry" inline.
- The loaded results are cached in `recent-snapshot.json` for the widget.
  Signing out clears both memory and the cache.

### Review tab and saved searches

- A **saved search** is `{ id, name, query, notifies }`: a GitHub search for
  pull requests. The first launch creates "Review requested"
  (`is:pr is:open archived:false review-requested:@me`, not notifying). It can
  be edited or deleted like any other. At most 10 searches (each one is a
  GitHub search on every refresh); "Add Search" is disabled at the limit.
- The Review tab lists the results of every saved search, in the user's order.
  With more than one search, results are grouped under a small header with the
  search name and count; with one search there is no header. A PR found by
  several searches is listed under the first one only, and searches with
  nothing to show are left out. Rows are the Open rows plus the author (avatar
  and login). The tab badge is the number of unique PRs, in a neutral colour.
  Within each search, the display uses newest creation first and related boxes,
  regardless of a `sort:` qualifier. Search qualifiers still determine the fetched result set.
- States: "Nothing to review" when every search is empty; "No searches" with an
  "Add Search" button (opens Settings) when there are none; a spinner for a
  search not fetched yet; a "Couldn't load "name". Retry" row for a search
  whose last fetch failed (its last result stays listed).
- Avatars load only from `https://avatars.githubusercontent.com`
  (`GitHubURL.isTrustedAvatar`); otherwise a grey circle is shown.

#### Adding a search

The user pastes either a link or a search; `SavedSearchLink.query(from:)`
turns it into the query that is run, shown live under the field:

- `https://github.com/<owner>/<repo>/pulls?q=…` (or `/issues`) → the decoded
  `q` (`+` is a space) plus ` AND repo:<owner>/<repo>`, unless the query
  already has a (non-negated) `repo:`, `org:` or `user:` qualifier.
- `https://github.com/pulls?q=…` or `https://github.com/issues?q=…` → `q`.
- Anything that is not a link → the trimmed text.
- If the result has no `is:pr` (or `type:pr`), `is:pr AND ` is put in front.
- Before ` AND repo:…` or `is:pr AND ` is added, a query with a top-level
  `OR` is wrapped in parentheses, since AND binds tighter than OR.
- A link to another host, another page, or without `q` is rejected.

#### Refresh and notifications

- Every refresh fetches my PRs, then each saved search one after another. A
  failing search only marks that search as failed. Saving an added or edited
  search fetches it right away.
- For a search with `notifies`, a PR whose id was not in that search's
  previous result sends "New PR to review" with
  `<repo>#<n> · <title> · by <author>`. The baseline is only results fetched
  during this run of the app, so the first fetch of a search (also after
  launch, or after its query changed) never notifies. A PR found by several
  notifying searches notifies once. Clicking opens the PR if
  `GitHubURL.isTrusted`.
- Signing out clears the results but keeps the saved searches.

#### Notification permission

- After sign-in (and at launch when already signed in) the app asks macOS for
  notification permission if it was never answered. The answer is read back
  into `PullRequestMonitor.notificationPermission` (`NotificationPermission`:
  unknown, notDetermined, allowed, denied), refreshed at every refresh and
  each time the panel window becomes key, since the user can change it in
  System Settings. The prompt never blocks sign-in.
- While not allowed, the panel shows a banner under the header. Denied:
  "Notifications are off" with "Open System Settings", which opens the app's
  own entry in the Notifications pane
  (`x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=<bundle id>`).
  Never answered: "Notifications aren't allowed yet" with "Allow
  Notifications", which shows the system prompt.
- Settings > General has a "Notifications" row: "Checking…" until read; "On";
  "Not allowed yet" with "Allow…" (shows the system prompt); "Off" with
  "Open System Settings…".

### Settings (inside the panel)

Settings is a screen of the menu bar panel, not a window: the panel shows one
`PanelRoute` at a time (`.list`, `.settings`, `.editSearch(SavedSearch?)`, `.editPrompt`),
switched with a short fade. The gear or ⌘, opens Settings; "‹ Back" (or ⌘[ /
Esc) returns. The panel keeps its screen when it closes, and the Add/Edit Search
form keeps what was typed (held by `PanelNavigation`, outside the views) until
Save or Back, so the user can leave to copy a GitHub link and come back. Heights
fit the content up to the same 60%-of-screen cap as the lists. One scrolling
form with four sections:

- **General**: refresh interval, launch at login, notifications (see above),
  version, check for updates, "Quit MyPRs".
- **Review**: "Searches shown in the Review tab": each search with its name,
  query, a notify toggle and a menu (Edit Search…, Move Up, Move Down, Delete
  Search), plus "Add Search". The editor is its own panel screen (Back, Save) with Name, "GitHub link or
  search" with the parsed query preview, and "Notify me about new pull
  requests".
- **AI review prompt**: "Edit prompt…" opens the prompt editor (see below).
- **Account**: signed-in login, organization access link, Sign Out (or Sign
  in with GitHub).

### AI review prompt

Every row (Open, Recent, Review) has a third icon in its fixed action column,
below "Copy branch name" and "Copy link": SF Symbol `sparkles`, help "Copy AI
review prompt". It copies the prompt template rendered for that pull request
and shows a check for about 1.2 s. The row's context menu has "Copy AI Review
Prompt" too.

`ReviewPromptTemplate.render(_:values:)` replaces `{{key}}` placeholders in one
pass; unknown placeholders stay as written. Keys: `url`, `title`, `repo`
(owner/name), `number`, `author` (login or "unknown"), `head`, `base`,
`additions`, `deletions`, `files`, `checks` ("passing 77/77", "failing 3/5",
"running", "none"; "n/a" for closed pull requests, which also have no author).
The default template and renderer live in `MyPRsKit` and are shared with the widget.

The custom template remains in the app's `UserDefaults` (key
`reviewPromptTemplate`; absent means the default; saving blank or the default
removes it), and is synchronized to the App Group for widget actions. Existing
custom templates are synchronized at app startup. The widget renders the prompt
using the shared template when the copy action runs. The editor (`.editPrompt`: Back, Save, monospaced text editor,
clickable placeholder chips that append, "Reset to Default…" with confirmation,
live preview with a sample pull request) keeps its draft in `PanelNavigation`
like the search editor.

### Widget

- Small, medium, large and extra large. Small shows counts, the others a list from the shared cache.
- List widgets keep their header, scoreboard (when shown) and update time visible; they show as many rows as fit and a `+N more` count for the rest.
- Tapping a row opens the PR. Each list row has copy-link, copy-branch and copy-AI-review-prompt buttons (App Intents), including medium widgets.
- Signed out / empty states with a short message. A Recent widget without a cache asks for an app refresh.
- Related boxes are compact and fit within the available widget height. A partially
  shown group reports its hidden members; the widget also reports the total omitted rows.
- Configurable: right-click → Edit "Pull requests" → "Show" picks **My pull
  requests** (default), **Recent pull requests**, or one of
  the saved searches by name. Each widget instance has its own source
  (`AppIntentConfiguration`, same kind `MyPRsWidget`; the intent is not
  discoverable in Shortcuts). A deleted search falls back to My pull requests,
  a renamed one shows its new name (`WidgetSource.resolve`).
- A search widget reads `snapshots/<search id>.json`, uses chronological related groups, and
  titles itself with the search name. The header pill is a neutral "N to
  review", there is no CI scoreboard, and rows show the author (initials circle
  and login, since widgets cannot reliably load remote avatars). Small shows
  the count and "to review". Empty: "Nothing to review".

## Architecture

```
┌──────────────── Mac ────────────────┐         ┌──────── Cloudflare ────────┐
│ MyPRs.app (menu bar)                │  login  │ myprs-auth Worker          │
│  LoginFlow ── default browser ──────┼────────▶│ GET /callback → page that  │
│                                     │ myprs:// │  opens myprs://auth?code…  │
│  AuthWorker ── HTTPS ───────────────┼────────▶│ POST /token  (code+PKCE)   │
│                                     │         │ POST /revoke (sign-out)    │
│  TokenStore (Keychain)              │         │                            │
│  PullRequestMonitor (timer)         │         │                            │
│   └ GitHubClient ──── GraphQL ──────┼──▶ api.github.com                    │
│   └ ChangeDetector → Notifier       │         └────────────────────────────┘
│   └ SnapshotStore.shared.save ─┐           │
│ MyPRsWidget.appex       │ App Group │
│   └ SnapshotStore.shared.load ◀┘           │
└─────────────────────────────────────┘
```

- **Worker** holds the OAuth client secret and stores nothing. It never puts
  the token in a URL or an HTML page.
  - `GET /callback` (GitHub's redirect) validates `code` (hex, at most 64
    characters) and `state`, and answers with a small HTML page that navigates
    to `myprs://auth?code=…&state=…` (or `?error=…&state=…`, passing GitHub's
    `error` such as `access_denied` through), with an "Open MyPRs" link as a
    manual fallback. The page's only script is allowed by its CSP hash; the
    response also sets `base-uri`, `form-action` and `frame-ancestors` to
    `'none'`, HSTS and `nosniff`.
  - `POST /token` takes JSON `{ code, code_verifier }`, exchanges it with GitHub
    (client id, client secret, code, PKCE verifier) and answers
    `{ access_token }` or `{ error }`. JSON only, `Cache-Control: no-store`, no
    CORS, no logging. Bodies over 4 KB get 413.
  - `POST /revoke` takes JSON `{ access_token }` and calls GitHub's
    `DELETE /applications/{client_id}/token`; answers 204.
  - A known path with the wrong method gets 405 with `Allow`; anything else 404.
- **Login** happens in the user's default browser with PKCE (RFC 7636, S256):
  the app creates a random verifier per sign-in and opens the GitHub authorize
  URL (with `state` and `code_challenge`) with `NSWorkspace`, then waits for
  the `myprs://auth` callback, delivered to `AppDelegate.application(_:open:)`
  and routed to `LoginFlow`. Only a `myprs://auth` URL carrying the pending
  `state` completes the sign-in; anything else is ignored. The app then posts
  the code and verifier to the Worker's `/token` over HTTPS and stores the
  token in the Keychain (if the Keychain refuses it, the fresh token is revoked
  and an error is shown). A leaked code is useless without the verifier.
  Starting a new sign-in cancels a pending one.
- **Sign-out** asks the Worker to revoke the token (fire and forget, failures
  ignored), then deletes it locally.
- **App** talks to GitHub directly with the token. It is the only process that
  holds the token and does network calls.
- **Widget** never calls the network. It reads `snapshot.json` from the App
  Group container. The app reloads the widget timelines when the snapshot or
  a saved search's results change; it also reloads them when the saved searches are added, edited, renamed, reordered or deleted, so the picker and content refresh.

### Storage (App Group container)

| File | Content |
|---|---|
| `snapshot.json` | `PullRequestSnapshot`, my open PRs |
| `recent-snapshot.json` | `ClosedPullRequestSnapshot`, loaded closed/merged PRs |
| `saved-searches.json` | `[SavedSearch]` in display order (missing → the built-in "Review requested") |
| `snapshots/<search id>.json` | `SavedSearchSnapshot`, the last result of one saved search, read by the Review tab and by widgets showing that search |

Files are written atomically with permissions `0600`.

### Identifiers

| Thing | Value |
|---|---|
| Bundle id (app) | `com.zaintech.myprs` |
| Bundle id (widget) | `com.zaintech.myprs.widget` |
| App Group | `688YYDN5Z4.com.zaintech.myprs` |
| Team | Zaintech LTDA, `688YYDN5Z4`, Developer ID |
| URL scheme | `myprs` |
| Worker | `myprs-auth`, served at `https://myprs-auth.zaintech.com.br` |
| OAuth scopes | `repo` (read private repos), `read:org` (list organization memberships for the access check) |
| Update feed | `https://github.com/jaugustodafranca/myprs/releases/latest/download/appcast.xml` |

The app is not sandboxed (Developer ID distribution, needed for Sparkle without
extra XPC setup). The widget extension is sandboxed, as WidgetKit requires.

### Shared types (`Packages/MyPRsKit`, linked by app and widget)

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
    let createdAt: Date
    let additions: Int
    let deletions: Int
    let changedFiles: Int
    let headBranch: String    // headRefName
    let baseBranch: String    // baseRefName
    let headRepository: String? // head repository owner/name; nil in older snapshots
    let hasConflicts: Bool    // mergeable == CONFLICTING
    let checksPassed: Int     // CheckRun SUCCESS/NEUTRAL/SKIPPED + StatusContext SUCCESS
    let checksTotal: Int      // all check contexts (first 100)
    let approvals: Int        // latestReviews with state APPROVED
    let authorLogin: String?  // nil in snapshots saved before authors were fetched
    let authorAvatarURL: URL? // only https://avatars.githubusercontent.com
    var needsAttention: Bool { checks == .failing || unansweredThreads > 0 }
}
enum CheckStatus: String, Codable { case passing, failing, running, none }
enum ReviewStatus: String, Codable { case approved, changesRequested, waiting }

struct PullRequestSnapshot: Codable {
    let login: String
    let pullRequests: [PullRequest]
    let fetchedAt: Date
}

struct SavedSearch: Codable, Hashable, Identifiable {
    let id: UUID
    var name: String
    var query: String
    var notifies: Bool
    static let reviewRequested: SavedSearch
}

struct SavedSearchSnapshot: Codable {
    let searchID: UUID
    let pullRequests: [PullRequest]
    let fetchedAt: Date
}

struct SavedSearchStore {
    static let shared: SavedSearchStore
    init(directory: URL)
    func loadSearches() -> [SavedSearch]
    func saveSearches(_ searches: [SavedSearch])
    func loadSnapshot(for searchID: UUID) -> SavedSearchSnapshot?
    func saveSnapshot(_ snapshot: SavedSearchSnapshot)
    func removeSnapshot(for searchID: UUID)
    func clearSnapshots()
}

struct SnapshotStore {
    static let shared: SnapshotStore   // App Group container
    init(directory: URL)               // tests pass a temporary directory
    func load() -> PullRequestSnapshot?
    func save(_ snapshot: PullRequestSnapshot)
    func clear()
}

enum AppConfig { appGroupID, urlScheme, gitHubClientID, authBaseURL, authCallbackURL, ... }
```

### GitHub query

Each refresh fetches my open PRs, Recent when stale, then each saved search.
Open PRs and saved searches select the same fields through `PullRequestFields`:

```graphql
query {
  viewer { login }
  search(query: "is:pr is:open author:@me archived:false sort:created-desc", type: ISSUE, first: 50) {
    nodes { ...PullRequestFields }
  }
}

query($q: String!) {
  viewer { login }
  search(query: $q, type: ISSUE_ADVANCED, first: 50) {
    nodes { ...PullRequestFields }
  }
}

fragment PullRequestFields on PullRequest {
  id number title url isDraft updatedAt createdAt reviewDecision
  additions deletions changedFiles headRefName baseRefName mergeable
  author { login avatarUrl }
  repository { nameWithOwner }
  headRepository { nameWithOwner }
  latestReviews(first: 20) { nodes { state } }
  commits(last: 1) {
    nodes {
      commit {
        statusCheckRollup {
          state
          contexts(first: 100) {
            nodes {
              ... on CheckRun { conclusion }
              ... on StatusContext { state }
            }
          }
        }
      }
    }
  }
  reviewThreads(first: 100) {
    nodes { isResolved comments(last: 1) { nodes { author { login } } } }
  }
}
```

`ISSUE_ADVANCED` accepts `AND`, `OR` and parentheses, as GitHub's web search
does, so a copied link works as is.

Snapshots without `headRepository` still decode, but cannot supply parent branch
identity for grouping until refreshed. A snapshot missing other required fields
fails to decode; `SnapshotStore.load()` returns nil and the next refresh replaces it.

### Recent query

Sent on demand by the Recent tab, one request per page (`$after` is the
previous page's `endCursor`, null for the first page):

```graphql
query($after: String) {
  search(query: "is:pr author:@me is:closed archived:false sort:created-desc", type: ISSUE, first: 20, after: $after) {
    pageInfo { hasNextPage endCursor }
    nodes {
      ... on PullRequest {
        id number title url state createdAt mergedAt closedAt
        additions deletions changedFiles headRefName baseRefName
        repository { nameWithOwner }
        headRepository { nameWithOwner }
      }
    }
  }
}
```

`state` is `MERGED` or `CLOSED`; the time shown is `mergedAt` or `closedAt`
accordingly.

### Organization access check

Organizations with "OAuth App access restrictions" hide their repositories from
the token, so their PRs silently go missing. A separate GraphQL request
(`OrganizationAccessQuery`) lists `viewer.organizations` with
`repositories(first: 1)`. For a restricted organization GitHub returns partial
data plus an error with `type: "FORBIDDEN"` and a path
`["viewer","organizations","nodes",<index>,"repositories"]`;
`RestrictedOrganizations.from` maps those indices back to logins.

- Runs after a successful PR refresh, at most every 30 minutes, or on demand
  ("Check again"). Failures are ignored and never affect the PR list.
- If the `X-OAuth-Scopes` response header lacks `read:org`, the check is
  skipped and the panel asks the user to sign in again.
- The panel shows a banner above the list: "<org> hasn't approved MyPRs" (or
  "N organizations haven't approved MyPRs" with the names) and a "Request
  access" button that opens the app's authorized-apps page. The menu bar icon
  colour is unaffected.

### Branch

The UI offers copying the PR's head branch name and the command
`git checkout <headBranch>`.

### Errors

- HTTP 401 from GitHub → token is revoked: delete it, clear the snapshot, show
  the signed-out state.
- Network or other errors → keep the last snapshot, show a small "Couldn't
  refresh" line with the time of the last success. Retry on the next tick.
- Login: state mismatch, user cancel, or `error=` in callback → stay signed out
  and show the reason.

### Token storage and URL trust

- The token lives in the legacy login keychain (service `com.zaintech.myprs`,
  account `github-token`). `kSecAttrAccessible` is not set: it only applies to
  the data-protection keychain. Saving updates the existing item in place, so
  tokens saved by older versions keep loading. Every `SecItem*` status is checked and a failed save is shown to the user.
- Limitation: the data-protection keychain (`kSecUseDataProtectionKeychain`)
  needs the `keychain-access-groups` entitlement, which is restricted. Verified
  with a Developer ID build and no provisioning profile: Xcode refuses to sign
  it, and a manually re-signed copy is killed by AMFI ("No matching profile
  found"). Without the entitlement SecItem returns -34018. Moving over requires
  creating a Developer ID provisioning profile for the app.
- Pull request URLs are opened or linked only when `GitHubURL.isTrusted`
  (https and host `github.com`). Mappers drop other pull requests, and the
  widget filters the snapshot again when it reads it.

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
  login callback parsing, saved search links, Review sections, new-PR
  detection, notification permission states, storage, worker handler.
