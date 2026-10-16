import Foundation
import MyPRsKit

extension PullRequestEntry {
    static let sample = entry(samplePullRequests)
    static let calm = entry(samplePullRequests.filter { !$0.needsAttention })
    static let empty = entry([])
    static let signedOut = PullRequestEntry(date: .now, source: .mine, snapshot: nil, recentSnapshot: nil, isSignedOut: true)
    static let reviewSample = entry(reviewPullRequests, source: reviewSearch)
    static let reviewEmpty = entry([], source: reviewSearch)

    private static let reviewSearch = WidgetSource.search(.reviewRequested)

    private static func entry(_ pullRequests: [PullRequest], source: WidgetSource = .mine) -> PullRequestEntry {
        PullRequestEntry(
            date: .now,
            source: source,
            snapshot: PullRequestSnapshot(login: "octo", pullRequests: pullRequests, fetchedAt: .now),
            recentSnapshot: nil
        )
    }

    static let reviewPullRequests = [
        PullRequest.sample(
            11, "Handle partial refunds in the ledger export", repository: "acme/billing-api",
            checks: .passing, passed: 5, total: 5, additions: 320, deletions: 41, files: 9,
            head: "feature/partial-refunds", author: "maria-lopes"
        ),
        PullRequest.sample(
            12, "Bump Postgres driver to 4.2", repository: "acme/storefront-web",
            checks: .failing, passed: 2, total: 4, additions: 8, deletions: 8, files: 2,
            head: "chore/pg-driver", author: "tchen"
        ),
        PullRequest.sample(
            13, "Add retry with backoff to webhook sender", repository: "acme/notifications",
            checks: .running, passed: 1, total: 3, additions: 144, deletions: 20, files: 5,
            head: "feature/webhook-retry", author: "dev-anand"
        ),
        PullRequest.sample(
            14, "Fix typo in onboarding copy", repository: "acme/storefront-web",
            checks: .passing, passed: 3, total: 3, additions: 1, deletions: 1, files: 1,
            head: "docs/onboarding-typo", author: "sam-k"
        ),
    ]

    static let samplePullRequests = [
        PullRequest.sample(
            1, "Fix flaky checkout test that fails whenever the payment sandbox is slow to respond",
            repository: "acme/storefront-web", checks: .failing, passed: 3, total: 5,
            threads: 0, additions: 214, deletions: 38, files: 7,
            head: "fix/checkout-flaky-payment-sandbox-timeout-handling"
        ),
        PullRequest.sample(
            2, "Add dark mode to settings", checks: .passing, passed: 4, total: 4, review: .changesRequested,
            threads: 2, additions: 1240, deletions: 310, files: 23, head: "feature/dark-mode"
        ),
        PullRequest.sample(
            3, "Upgrade Swift toolchain", checks: .passing, passed: 6, total: 6, review: .approved,
            additions: 12, deletions: 12, files: 2, head: "chore/swift-6"
        ),
        PullRequest.sample(
            4, "Refactor auth middleware", checks: .running, passed: 2, total: 5,
            additions: 18_400, deletions: 9_200, files: 142, conflicts: true, head: "refactor/auth-middleware"
        ),
        PullRequest.sample(5, "Docs: release process", checks: .none, additions: 40, deletions: 2, files: 1, head: "docs/release"),
        PullRequest.sample(
            6, "Draft: migrate the billing service", checks: .passing, passed: 3, total: 3, draft: true,
            additions: 560, deletions: 120, files: 18, head: "feature/billing-migration"
        ),
    ]
}

extension PullRequest {
    static func sample(
        _ number: Int,
        _ title: String,
        repository: String = "octo/repo",
        checks: CheckStatus,
        passed: Int = 0,
        total: Int = 0,
        review: ReviewStatus = .waiting,
        threads: Int = 0,
        draft: Bool = false,
        additions: Int,
        deletions: Int,
        files: Int,
        conflicts: Bool = false,
        head: String,
        author: String? = nil
    ) -> PullRequest {
        PullRequest(
            id: "PR_\(number)",
            number: number,
            title: title,
            url: URL(string: "https://github.com/\(repository)/pull/\(number)")!,
            repository: repository,
            isDraft: draft,
            checks: checks,
            review: review,
            unansweredThreads: threads,
            updatedAt: Date(timeIntervalSinceNow: -Double(number) * 3600),
            createdAt: Date(timeIntervalSinceNow: -Double(number) * 86400),
            additions: additions,
            deletions: deletions,
            changedFiles: files,
            headBranch: head,
            baseBranch: "main",
            hasConflicts: conflicts,
            checksPassed: passed,
            checksTotal: total,
            approvals: review == .approved ? 1 : 0,
            authorLogin: author
        )
    }
}
