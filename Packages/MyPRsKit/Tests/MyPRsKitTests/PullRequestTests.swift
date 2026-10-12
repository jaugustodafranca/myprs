import Foundation
@testable import MyPRsKit
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
