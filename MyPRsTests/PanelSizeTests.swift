@testable import MyPRs
import Testing

@Suite struct PanelSizeTests {
    @Test func listMayUseSixtyPercentOfTheScreenMinusTheMeasuredChrome() {
        #expect(PanelSize.maxListHeight(screenHeight: 1000, chromeHeight: 80) == 520)
    }

    @Test func tallerChromeTakesSpaceFromTheList() {
        #expect(PanelSize.maxListHeight(screenHeight: 1000, chromeHeight: 300) == 300)
    }

    @Test func listKeepsAUsableHeightOnSmallScreens() {
        #expect(PanelSize.maxListHeight(screenHeight: 400, chromeHeight: 300) == 150)
    }
}
