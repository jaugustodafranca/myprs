import Foundation

/// Sample data only the panel shows: the Recent tab lists app-only closed pull request types.
extension SampleData {
    static let closedPullRequests = [
        closedPullRequest(
            478, "Fix double-charged orders after a payment retry",
            repository: "acme/storefront", head: "fix/double-charge-on-retry",
            state: .merged, endedAt: ago(hours: 3), createdAt: ago(days: 4), additions: 64, deletions: 18, files: 4
        ),
        closedPullRequest(
            481, "Add a checkout retry regression test",
            repository: "acme/storefront", head: "test/checkout-retry-regression", base: "fix/double-charge-on-retry",
            state: .merged, endedAt: ago(hours: 5), createdAt: ago(days: 1), additions: 29, deletions: 2, files: 1
        ),
        closedPullRequest(
            480, "Guard the retry path against duplicate charges",
            repository: "acme/storefront", head: "fix/retry-duplicate-charge", base: "fix/double-charge-on-retry",
            state: .merged, endedAt: ago(hours: 4), createdAt: ago(days: 2), additions: 43, deletions: 7, files: 3
        ),
        closedPullRequest(
            470, "Remove the legacy report exporter",
            repository: "northwind/reports", head: "chore/remove-legacy-exporter",
            state: .merged, endedAt: ago(days: 1), createdAt: ago(days: 3), additions: 12, deletions: 1_480, files: 31
        ),
        closedPullRequest(
            462, "Try a Redis-backed session store",
            repository: "octo/api", head: "spike/redis-sessions",
            state: .closed, endedAt: ago(days: 3), createdAt: ago(days: 5), additions: 410, deletions: 22, files: 9
        ),
        closedPullRequest(
            457, "Bump the image resizer to the latest minor release",
            repository: "acme/storefront", head: "chore/image-resizer-bump", base: "release/2.0-stabilization",
            state: .merged, endedAt: ago(days: 6), createdAt: ago(days: 8), additions: 3, deletions: 3, files: 1
        ),
    ]

    private static func closedPullRequest(
        _ number: Int,
        _ title: String,
        repository: String,
        head: String,
        base: String = "main",
        state: ClosedState,
        endedAt: Date,
        createdAt: Date,
        additions: Int,
        deletions: Int,
        files: Int
    ) -> ClosedPullRequest {
        ClosedPullRequest(
            id: "\(repository)#\(number)",
            number: number,
            title: title,
            url: URL(string: "https://github.com/\(repository)/pull/\(number)")!,
            repository: repository,
            headBranch: head,
            baseBranch: base,
            state: state,
            endedAt: endedAt,
            additions: additions,
            deletions: deletions,
            changedFiles: files,
            createdAt: createdAt,
            headRepository: repository
        )
    }
}
