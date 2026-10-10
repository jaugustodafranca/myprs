import Testing

@Suite struct OpenCountBadgeTests {
    @Test func hiddenWhenNothingIsOpen() {
        #expect(OpenCountBadge(PanelSummary(open: 0, failing: 0, toAnswer: 0, ready: 0)) == nil)
    }

    @Test func redWhenAnyCheckIsFailing() {
        let badge = OpenCountBadge(PanelSummary(open: 4, failing: 1, toAnswer: 2, ready: 0))
        #expect(badge?.count == 4)
        #expect(badge?.tone == .failing)
    }

    @Test func orangeWhenOnlyThreadsNeedAnswers() {
        let badge = OpenCountBadge(PanelSummary(open: 3, failing: 0, toAnswer: 1, ready: 0))
        #expect(badge?.tone == .toAnswer)
    }

    @Test func neutralOtherwise() {
        #expect(OpenCountBadge(PanelSummary(open: 2, failing: 0, toAnswer: 0, ready: 1))?.tone == .neutral)
        #expect(OpenCountBadge(PanelSummary(open: 2, failing: 0, toAnswer: 0, ready: 0))?.tone == .neutral)
    }

    @Test func accessibilityLabelSpellsOutTheCount() {
        #expect(OpenCountBadge(PanelSummary(open: 4, failing: 0, toAnswer: 0, ready: 0))?.accessibilityLabel == "Open, 4 pull requests")
        #expect(OpenCountBadge(PanelSummary(open: 1, failing: 0, toAnswer: 0, ready: 0))?.accessibilityLabel == "Open, 1 pull request")
    }
}
