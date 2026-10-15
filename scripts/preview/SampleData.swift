import Foundation

/// Fictional pull requests, searches and snapshots shared by the panel and widget previews.
/// Keep every name made up: no real organization, repository or person belongs here.
enum SampleData {
    static let login = "jdoe"

    // MARK: Saved searches

    static let reviewRequestedSearch = SavedSearch(
        id: UUID(uuidString: "6D1F0C2A-5B7E-4C3A-9E10-0A1B2C3D4E01")!,
        name: "Review requested",
        query: "is:pr is:open archived:false review-requested:@me"
    )

    static let apiTeamSearch = SavedSearch(
        id: UUID(uuidString: "6D1F0C2A-5B7E-4C3A-9E10-0A1B2C3D4E02")!,
        name: "API team",
        query: "is:pr is:open repo:octo/api -author:@me -reviewed-by:@me",
        notifies: true
    )

    static let savedSearches = [reviewRequestedSearch, apiTeamSearch]

    // MARK: Snapshots

    static var openSnapshot: PullRequestSnapshot { snapshot(of: openPullRequests) }

    static var searchSnapshots: [SavedSearchSnapshot] {
        [
            SavedSearchSnapshot(searchID: reviewRequestedSearch.id, pullRequests: reviewRequestedPullRequests, fetchedAt: ago(minutes: 2)),
            SavedSearchSnapshot(searchID: apiTeamSearch.id, pullRequests: apiTeamPullRequests, fetchedAt: ago(minutes: 2)),
        ]
    }

    static func snapshot(of pullRequests: [PullRequest]) -> PullRequestSnapshot {
        PullRequestSnapshot(login: login, pullRequests: pullRequests, fetchedAt: ago(minutes: 2))
    }

    // MARK: Pull requests of the signed-in user

    static let openPullRequests = [
        pullRequest(
            482, "Retry checkout session creation when the payment token expired",
            repository: "acme/storefront", head: "fix/checkout-session-retry",
            checks: .failing, passed: 3, total: 5, additions: 214, deletions: 38, files: 7, createdAt: ago(days: 2)
        ),
        pullRequest(
            471, "Add per-tenant rate limits to the public API",
            repository: "octo/api",
            head: "feature/per-tenant-rate-limits-with-sliding-window-and-burst-allowance-for-enterprise-plans",
            checks: .running, passed: 2, total: 6, threads: 3, additions: 1_240, deletions: 310, files: 23, createdAt: ago(days: 5)
        ),
        pullRequest(
            466, "Move weekly report generation to the job queue",
            repository: "northwind/reports", head: "refactor/report-job-queue",
            checks: .passing, passed: 8, total: 8, review: .approved, approvals: 2, additions: 96, deletions: 71, files: 6, createdAt: ago(days: 1)
        ),
        pullRequest(
            459, "Cache product search results for anonymous visitors",
            repository: "acme/storefront", head: "perf/search-result-cache",
            checks: .passing, passed: 5, total: 5, review: .changesRequested, threads: 1, additions: 188, deletions: 24, files: 5, createdAt: ago(days: 3)
        ),
        pullRequest(
            455, "Upgrade the Postgres driver to the 4.x series",
            repository: "octo/api", head: "chore/postgres-driver-4", base: "release/2.0-stabilization",
            checks: .passing, passed: 6, total: 6, conflicts: true, additions: 18_400, deletions: 9_200, files: 142, createdAt: ago(days: 8)
        ),
        pullRequest(
            448, "Draft: render invoice PDFs without the headless browser",
            repository: "northwind/reports", head: "spike/invoice-pdf-renderer",
            checks: .none, isDraft: true, additions: 640, deletions: 15, files: 11, createdAt: ago(days: 12)
        ),
        pullRequest(
            441, "Stabilise the nightly export integration test that fails whenever the sandbox clock drifts",
            repository: "octo/api", head: "test/nightly-export-clock-drift",
            checks: .passing, passed: 4, total: 4, additions: 12, deletions: 12, files: 2, createdAt: ago(hours: 6)
        ),
    ]

    // MARK: Pull requests found by the saved searches

    static let reviewRequestedPullRequests = [
        pullRequest(
            512, "Handle partial refunds in the ledger export",
            repository: "acme/storefront", head: "feature/partial-refunds", author: "mrivera",
            checks: .passing, passed: 5, total: 5, additions: 320, deletions: 41, files: 9, createdAt: ago(hours: 5)
        ),
        pullRequest(
            508, "Fix timezone drift in the weekly report email",
            repository: "northwind/reports", head: "fix/report-timezones", author: "kpatel",
            checks: .failing, passed: 4, total: 6, threads: 1, additions: 45, deletions: 12, files: 3, createdAt: ago(days: 1)
        ),
        pullRequest(
            497, "Add retry with backoff to the webhook sender",
            repository: "octo/api", head: "feature/webhook-retry-with-exponential-backoff", author: "alee",
            checks: .running, passed: 1, total: 3, additions: 144, deletions: 20, files: 5, createdAt: ago(days: 2)
        ),
    ]

    static let apiTeamPullRequests = [
        pullRequest(
            503, "Paginate the audit log endpoint",
            repository: "octo/api", head: "feature/audit-log-pagination", author: "alee",
            checks: .passing, passed: 7, total: 7, review: .approved, approvals: 1, additions: 210, deletions: 33, files: 8, createdAt: ago(days: 3)
        ),
        pullRequest(
            499, "Return 429 with a Retry-After header",
            repository: "octo/api", head: "fix/rate-limit-response", author: "mrivera",
            checks: .passing, passed: 7, total: 7, additions: 36, deletions: 4, files: 2, createdAt: ago(days: 4)
        ),
    ]

    // MARK: Builder

    private static func pullRequest(
        _ number: Int,
        _ title: String,
        repository: String,
        head: String,
        base: String = "main",
        author: String = login,
        checks: CheckStatus,
        passed: Int = 0,
        total: Int = 0,
        review: ReviewStatus = .waiting,
        approvals: Int = 0,
        threads: Int = 0,
        isDraft: Bool = false,
        conflicts: Bool = false,
        additions: Int,
        deletions: Int,
        files: Int,
        createdAt: Date
    ) -> PullRequest {
        PullRequest(
            id: "\(repository)#\(number)",
            number: number,
            title: title,
            url: URL(string: "https://github.com/\(repository)/pull/\(number)")!,
            repository: repository,
            isDraft: isDraft,
            checks: checks,
            review: review,
            unansweredThreads: threads,
            updatedAt: createdAt,
            createdAt: createdAt,
            additions: additions,
            deletions: deletions,
            changedFiles: files,
            headBranch: head,
            baseBranch: base,
            hasConflicts: conflicts,
            checksPassed: passed,
            checksTotal: total,
            approvals: approvals,
            authorLogin: author
        )
    }

    static func ago(days: Double = 0, hours: Double = 0, minutes: Double = 0) -> Date {
        Date(timeIntervalSinceNow: -(days * 24 * 3600 + hours * 3600 + minutes * 60))
    }
}
