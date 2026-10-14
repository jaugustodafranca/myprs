import Foundation
@testable import MyPRsKit
import Testing

@Suite struct SavedSearchStoreTests {
    private let store: SavedSearchStore

    init() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        store = SavedSearchStore(directory: directory)
    }

    @Test func startsWithTheReviewRequestedSearch() {
        #expect(store.loadSearches() == [.reviewRequested])
    }

    @Test func reviewRequestedDoesNotNotifyByDefault() {
        #expect(SavedSearch.reviewRequested.notifies == false)
        #expect(SavedSearch.reviewRequested.query == "is:pr is:open archived:false review-requested:@me")
    }

    @Test func savedSearchesAreLoadedBackInOrder() {
        let searches = [
            SavedSearch(name: "Team", query: "is:pr author:a", notifies: true),
            SavedSearch(name: "Mine", query: "is:pr author:@me"),
        ]
        store.saveSearches(searches)
        #expect(store.loadSearches() == searches)
    }

    @Test func anEmptyListStaysEmpty() {
        store.saveSearches([])
        #expect(store.loadSearches().isEmpty)
    }

    @Test func snapshotsAreStoredPerSearch() {
        let first = SavedSearchSnapshot(searchID: UUID(), pullRequests: [makePullRequest(id: "A")], fetchedAt: Date(timeIntervalSince1970: 1_700_000_000))
        let second = SavedSearchSnapshot(searchID: UUID(), pullRequests: [], fetchedAt: Date(timeIntervalSince1970: 1_700_000_100))
        store.saveSnapshot(first)
        store.saveSnapshot(second)

        #expect(store.loadSnapshot(for: first.searchID) == first)
        #expect(store.loadSnapshot(for: second.searchID) == second)
    }

    @Test func removeSnapshotOnlyRemovesThatSearch() {
        let kept = SavedSearchSnapshot(searchID: UUID(), pullRequests: [], fetchedAt: .now)
        let removed = SavedSearchSnapshot(searchID: UUID(), pullRequests: [], fetchedAt: .now)
        store.saveSnapshot(kept)
        store.saveSnapshot(removed)

        store.removeSnapshot(for: removed.searchID)

        #expect(store.loadSnapshot(for: removed.searchID) == nil)
        #expect(store.loadSnapshot(for: kept.searchID) != nil)
    }

    @Test func clearSnapshotsKeepsTheSearches() {
        let search = SavedSearch(name: "Team", query: "is:pr")
        store.saveSearches([search])
        store.saveSnapshot(SavedSearchSnapshot(searchID: search.id, pullRequests: [], fetchedAt: .now))

        store.clearSnapshots()

        #expect(store.loadSnapshot(for: search.id) == nil)
        #expect(store.loadSearches() == [search])
    }
}
