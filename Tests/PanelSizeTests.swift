import Testing

@Suite struct PanelSizeTests {
    @Test func listFillsTheTargetPanelHeightWhenItIsShort() {
        let heights = PanelSize.listHeights(screenHeight: 1000, showsSettings: false)
        #expect(heights.lowerBound == 491)
    }

    @Test func listGrowsToThreeQuartersOfTheScreen() {
        let heights = PanelSize.listHeights(screenHeight: 1200, showsSettings: false)
        #expect(heights.upperBound == 831)
    }

    @Test func listNeverExceedsWhatItsMinimumAllows() {
        let heights = PanelSize.listHeights(screenHeight: 400, showsSettings: false)
        #expect(heights.lowerBound <= heights.upperBound)
        #expect(heights.upperBound == 231)
    }

    @Test func openSettingsTakeSpaceFromTheList() {
        let open = PanelSize.listHeights(screenHeight: 900, showsSettings: true)
        #expect(open.lowerBound == 291)
        #expect(open.upperBound == 406)
    }

    @Test func listKeepsAUsableHeightOnTinyScreens() {
        let heights = PanelSize.listHeights(screenHeight: 500, showsSettings: true)
        #expect(heights == 150...150)
    }
}
