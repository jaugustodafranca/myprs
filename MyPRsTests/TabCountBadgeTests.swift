@testable import MyPRs
import MyPRsKit
import Testing

@Suite struct TabCountBadgeTests {
    @Test func hiddenWhenNothingIsOpen() {
        #expect(TabCountBadge(PanelSummary(open: 0, failing: 0, toAnswer: 0, ready: 0)) == nil)
    }

    @Test func redWhenAnyCheckIsFailing() {
        let badge = TabCountBadge(PanelSummary(open: 4, failing: 1, toAnswer: 2, ready: 0))
        #expect(badge?.count == 4)
        #expect(badge?.tone == .failing)
    }

    @Test func orangeWhenOnlyThreadsNeedAnswers() {
        let badge = TabCountBadge(PanelSummary(open: 3, failing: 0, toAnswer: 1, ready: 0))
        #expect(badge?.tone == .toAnswer)
    }

    @Test func neutralOtherwise() {
        #expect(TabCountBadge(PanelSummary(open: 2, failing: 0, toAnswer: 0, ready: 1))?.tone == .neutral)
        #expect(TabCountBadge(PanelSummary(open: 2, failing: 0, toAnswer: 0, ready: 0))?.tone == .neutral)
    }

    @Test func accessibilityLabelSpellsOutTheCount() {
        #expect(TabCountBadge(PanelSummary(open: 4, failing: 0, toAnswer: 0, ready: 0))?.accessibilityLabel == "Open, 4 pull requests")
        #expect(TabCountBadge(PanelSummary(open: 1, failing: 0, toAnswer: 0, ready: 0))?.accessibilityLabel == "Open, 1 pull request")
    }

    @Test func reviewBadgeIsNeutralAndHiddenWhenEmpty() {
        #expect(TabCountBadge(reviewCount: 0) == nil)
        let badge = TabCountBadge(reviewCount: 6)
        #expect(badge?.tone == .neutral)
        #expect(badge?.accessibilityLabel == "Review, 6 pull requests")
    }
}
