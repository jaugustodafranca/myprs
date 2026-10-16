import Foundation
@testable import MyPRsKit
import Testing

@Suite struct PullRequestSortingTests {
    @Test func newestCreatedPRComesFirstWithStableIDTieBreak() {
        let oldAttention = makeSortablePullRequest(id: "old-attention", failing: true, updatedAt: 100)
        let newCalm = makeSortablePullRequest(id: "new-calm", failing: false, updatedAt: 400)
        let newAttention = makeSortablePullRequest(id: "new-attention", failing: true, updatedAt: 300)
        let oldCalm = makeSortablePullRequest(id: "old-calm", failing: false, updatedAt: 200)

        let sorted = [oldCalm, newCalm, oldAttention, newAttention].sortedForDisplay()

        #expect(sorted.map(\.id) == ["new-calm", "new-attention", "old-calm", "old-attention"])
    }
}

private func makeSortablePullRequest(id: String, failing: Bool, updatedAt: TimeInterval) -> PullRequest {
    makePullRequest(
        id: id,
        checks: failing ? .failing : .passing,
        updatedAt: Date(timeIntervalSince1970: updatedAt),
        createdAt: Date(timeIntervalSince1970: updatedAt)
    )
}
