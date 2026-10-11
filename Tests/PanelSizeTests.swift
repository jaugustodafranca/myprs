import Testing

@Suite struct PanelSizeTests {
    @Test func listMayUseSixtyPercentOfTheScreenMinusTheHeader() {
        #expect(PanelSize.maxListHeight(screenHeight: 1000, showsSettings: false) == 531)
    }

    @Test func openSettingsTakeSpaceFromTheList() {
        #expect(PanelSize.maxListHeight(screenHeight: 1000, showsSettings: true) == 320)
    }

    @Test func listKeepsAUsableHeightOnSmallScreens() {
        #expect(PanelSize.maxListHeight(screenHeight: 400, showsSettings: true) == 150)
    }
}
