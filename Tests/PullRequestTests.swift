import Foundation
import Testing

@Suite struct PullRequestTests {
    @Test func failingChecksNeedAttention() {
        #expect(makePullRequest(checks: .failing).needsAttention)
    }

    @Test func unansweredThreadsNeedAttention() {
        #expect(makePullRequest(unansweredThreads: 1).needsAttention)
    }

    @Test func passingChecksWithoutThreadsDoNotNeedAttention() {
        #expect(!makePullRequest(checks: .passing, unansweredThreads: 0).needsAttention)
    }
}

func makePullRequest(
    checks: CheckStatus = .passing,
    unansweredThreads: Int = 0
) -> PullRequest {
    PullRequest(
        id: "PR_1",
        number: 42,
        title: "Add widget",
        url: URL(string: "https://github.com/octo/repo/pull/42")!,
        repository: "octo/repo",
        isDraft: false,
        checks: checks,
        review: .waiting,
        unansweredThreads: unansweredThreads,
        updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
    )
}
