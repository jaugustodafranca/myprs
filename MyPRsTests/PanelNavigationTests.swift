import Foundation
import MyPRsKit
import Testing
@testable import MyPRs

@MainActor
@Suite struct PanelNavigationTests {
    @Test func startsOnTheList() {
        #expect(PanelNavigation().route == .list)
    }

    @Test func addingASearchStartsWithAnEmptyDraft() {
        let navigation = PanelNavigation()
        navigation.draft.name = "left over"
        navigation.editSearch(nil)
        #expect(navigation.route == .editSearch(nil))
        #expect(navigation.draft == SavedSearchDraft())
    }

    @Test func editingASearchFillsTheDraftFromIt() {
        let search = SavedSearch(id: UUID(), name: "Mine", query: "is:pr author:@me", notifies: true)
        let navigation = PanelNavigation()
        navigation.editSearch(search)
        #expect(navigation.draft == SavedSearchDraft(search))
    }

    @Test func draftSurvivesUntilTheNextEdit() {
        let navigation = PanelNavigation()
        navigation.editSearch(nil)
        navigation.draft.name = "Half done"
        #expect(navigation.route == .editSearch(nil))
        #expect(navigation.draft.name == "Half done")
    }
}
