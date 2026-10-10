import Foundation

extension PullRequestEntry {
    static let sample = PullRequestEntry(
        date: .now,
        snapshot: PullRequestSnapshot(login: "octo", pullRequests: samplePullRequests, fetchedAt: .now)
    )
    static let empty = PullRequestEntry(
        date: .now,
        snapshot: PullRequestSnapshot(login: "octo", pullRequests: [], fetchedAt: .now)
    )
    static let signedOut = PullRequestEntry(date: .now, snapshot: nil)

    private static let samplePullRequests = [
        samplePullRequest(1, "Fix flaky checkout test", checks: .failing, review: .waiting, threads: 0),
        samplePullRequest(2, "Add dark mode to settings", checks: .passing, review: .changesRequested, threads: 2),
        samplePullRequest(3, "Upgrade Swift toolchain", checks: .passing, review: .approved, threads: 0),
        samplePullRequest(4, "Refactor auth middleware", checks: .running, review: .waiting, threads: 0),
        samplePullRequest(5, "Docs: release process", checks: .none, review: .waiting, threads: 0),
    ]

    private static func samplePullRequest(
        _ number: Int,
        _ title: String,
        checks: CheckStatus,
        review: ReviewStatus,
        threads: Int
    ) -> PullRequest {
        PullRequest(
            id: "PR_\(number)",
            number: number,
            title: title,
            url: URL(string: "https://github.com/octo/repo/pull/\(number)")!,
            repository: "octo/repo",
            isDraft: false,
            checks: checks,
            review: review,
            unansweredThreads: threads,
            updatedAt: Date(timeIntervalSinceNow: -Double(number) * 3600)
        )
    }
}
