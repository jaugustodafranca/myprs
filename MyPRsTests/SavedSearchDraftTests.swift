import Foundation
import MyPRsKit
@testable import MyPRs
import Testing

@Suite struct SavedSearchDraftTests {
    @Test func needsANameAndAUsableSearch() {
        #expect(!SavedSearchDraft(name: "", linkOrQuery: "is:pr").canSave)
        #expect(!SavedSearchDraft(name: "Team", linkOrQuery: "https://github.com/acme/web/pulls").canSave)
        #expect(SavedSearchDraft(name: "Team", linkOrQuery: "is:pr").canSave)
    }

    @Test func savesTheParsedQueryAndTrimmedName() {
        let id = UUID()
        let draft = SavedSearchDraft(name: "  Team ", linkOrQuery: "https://github.com/acme/web/pulls?q=is%3Aopen", notifies: true)
        #expect(draft.savedSearch(id: id) == SavedSearch(id: id, name: "Team", query: "is:pr AND is:open AND repo:acme/web", notifies: true))
    }

    @Test func editingStartsFromTheSavedSearch() {
        let search = SavedSearch(name: "Mine", query: "is:pr author:@me", notifies: true)
        #expect(SavedSearchDraft(search) == SavedSearchDraft(name: "Mine", linkOrQuery: "is:pr author:@me", notifies: true))
    }
}
