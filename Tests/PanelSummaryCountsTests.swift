import Foundation
import Testing

@Suite struct PanelSummaryCountsTests {
    @Test func summaryCountsWhatNeedsAttention() {
        let failing = makePullRequest(id: "failing", checks: .failing)
        let asked = makePullRequest(id: "asked", unansweredThreads: 2)
        let ready = makeApprovedPullRequest(id: "ready", hasConflicts: false)
        let conflicted = makeApprovedPullRequest(id: "conflicted", hasConflicts: true)

        let summary = PanelSummary([ready, conflicted, asked, failing])

        #expect(summary.open == 4)
        #expect(summary.failing == 1)
        #expect(summary.toAnswer == 1)
        #expect(summary.ready == 1)
        #expect(summary.needsAttention)
        #expect(summary.mostUrgent?.id == "failing" || summary.mostUrgent?.id == "asked")
    }

    @Test func nothingNeedsAttentionWhenAllIsCalm() {
        let summary = PanelSummary([makeApprovedPullRequest(id: "ready", hasConflicts: false)])
        #expect(!summary.needsAttention)
    }
}

private func makeApprovedPullRequest(id: String, hasConflicts: Bool) -> PullRequest {
    PullRequest(
        id: id, number: 1, title: "Ready", url: URL(string: "https://github.com/octo/repo/pull/1")!,
        repository: "octo/repo", isDraft: false, checks: .passing, review: .approved, unansweredThreads: 0,
        updatedAt: .now, createdAt: .now, additions: 1, deletions: 1, changedFiles: 1,
        headBranch: "feature", baseBranch: "main", hasConflicts: hasConflicts,
        checksPassed: 1, checksTotal: 1, approvals: 1
    )
}
