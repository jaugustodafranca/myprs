import Foundation
import Testing

@Suite struct PullRequestSortingTests {
    @Test func attentionComesFirstThenMostRecentlyUpdated() {
        let oldAttention = makeSortablePullRequest(id: "old-attention", failing: true, updatedAt: 100)
        let newCalm = makeSortablePullRequest(id: "new-calm", failing: false, updatedAt: 400)
        let newAttention = makeSortablePullRequest(id: "new-attention", failing: true, updatedAt: 300)
        let oldCalm = makeSortablePullRequest(id: "old-calm", failing: false, updatedAt: 200)

        let sorted = [oldCalm, newCalm, oldAttention, newAttention].sortedForDisplay()

        #expect(sorted.map(\.id) == ["new-attention", "old-attention", "new-calm", "old-calm"])
    }
}

private func makeSortablePullRequest(id: String, failing: Bool, updatedAt: TimeInterval) -> PullRequest {
    PullRequest(
        id: id,
        number: 1,
        title: id,
        url: URL(string: "https://github.com/octo/repo/pull/1")!,
        repository: "octo/repo",
        isDraft: false,
        checks: failing ? .failing : .passing,
        review: .waiting,
        unansweredThreads: 0,
        updatedAt: Date(timeIntervalSince1970: updatedAt)
    )
}
