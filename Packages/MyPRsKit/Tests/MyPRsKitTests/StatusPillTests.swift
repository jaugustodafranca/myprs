@testable import MyPRsKit
import Testing

@Suite struct StatusPillTests {
    @Test func failingChecksWinOverEverything() {
        let pill = StatusPill(PanelSummary(open: 5, failing: 2, toAnswer: 1, ready: 1))
        #expect(pill?.text == "2 failing")
        #expect(pill?.tone == .failing)
    }

    @Test func unansweredThreadsComeNext() {
        let pill = StatusPill(PanelSummary(open: 3, failing: 0, toAnswer: 2, ready: 1))
        #expect(pill?.text == "2 to answer")
        #expect(pill?.tone == .toAnswer)
    }

    @Test func allClearWhenNothingNeedsAttention() {
        let pill = StatusPill(PanelSummary(open: 3, failing: 0, toAnswer: 0, ready: 1))
        #expect(pill?.text == "All clear")
        #expect(pill?.tone == .clear)
    }

    @Test func plainCountWhenNothingIsReadyOrUrgent() {
        let pill = StatusPill(PanelSummary(open: 4, failing: 0, toAnswer: 0, ready: 0))
        #expect(pill?.text == "4 open")
        #expect(pill?.tone == .neutral)
    }

    @Test func noPillWithoutOpenPullRequests() {
        #expect(StatusPill(PanelSummary(open: 0, failing: 0, toAnswer: 0, ready: 0)) == nil)
    }
}
