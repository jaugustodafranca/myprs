import Foundation
import MyPRsKit
@testable import MyPRs
import Testing

@MainActor
@Suite struct SavedSearchesTests {
    private let store: SavedSearchStore
    private let team = SavedSearch(name: "Team", query: "is:pr team", notifies: true)
    private let quiet = SavedSearch(name: "Quiet", query: "is:pr quiet", notifies: false)

    init() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        store = SavedSearchStore(directory: directory)
        store.saveSearches([team, quiet])
    }

    private func fetch(_ results: [String: [String]]) -> SavedSearches.Fetch {
        { query in (results[query] ?? []).map { makePullRequest(id: $0) } }
    }

    @Test func firstRefreshNeverNotifies() async {
        let searches = SavedSearches(store: store)
        let outcome = await searches.refreshAll(using: fetch(["is:pr team": ["A"]]))
        #expect(outcome.newPullRequests.isEmpty)
        #expect(outcome.didChange)
        #expect(searches.snapshots[team.id]?.pullRequests.map(\.id) == ["A"])
    }

    @Test func notifiesNewPullRequestsOfNotifyingSearchesOnly() async {
        let searches = SavedSearches(store: store)
        _ = await searches.refreshAll(using: fetch(["is:pr team": ["A"], "is:pr quiet": ["Q"]]))
        let outcome = await searches.refreshAll(using: fetch(["is:pr team": ["A", "B"], "is:pr quiet": ["Q", "R"]]))
        #expect(outcome.newPullRequests.map(\.id) == ["B"])
    }

    @Test func aPullRequestInSeveralNotifyingSearchesNotifiesOnce() async {
        let other = SavedSearch(name: "Other", query: "is:pr other", notifies: true)
        store.saveSearches([team, other])
        let searches = SavedSearches(store: store)
        _ = await searches.refreshAll(using: fetch([:]))
        let outcome = await searches.refreshAll(using: fetch(["is:pr team": ["X"], "is:pr other": ["X"]]))
        #expect(outcome.newPullRequests.map(\.id) == ["X"])
    }

    @Test func persistedSnapshotsAreShownButAreNotABaseline() async {
        store.saveSnapshot(SavedSearchSnapshot(searchID: team.id, pullRequests: [makePullRequest(id: "A")], fetchedAt: .now))
        let searches = SavedSearches(store: store)
        #expect(searches.snapshots[team.id]?.pullRequests.map(\.id) == ["A"])

        let outcome = await searches.refreshAll(using: fetch(["is:pr team": ["A", "B"]]))
        #expect(outcome.newPullRequests.isEmpty)
    }

    @Test func oneFailingSearchDoesNotStopTheOthers() async {
        struct Failure: Error {}
        let searches = SavedSearches(store: store)
        _ = await searches.refreshAll { query in
            if query == "is:pr team" { throw Failure() }
            return [makePullRequest(id: "Q")]
        }
        #expect(searches.failedSearchIDs == [team.id])
        #expect(searches.snapshots[quiet.id]?.pullRequests.map(\.id) == ["Q"])
        #expect(store.loadSnapshot(for: quiet.id) != nil)
    }

    @Test func aSuccessfulRetryClearsTheError() async {
        struct Failure: Error {}
        let searches = SavedSearches(store: store)
        _ = await searches.refreshAll { _ in throw Failure() }
        _ = await searches.refresh(team.id, using: fetch(["is:pr team": ["A"]]))
        #expect(!searches.failedSearchIDs.contains(team.id))
    }

    @Test func changingTheQueryStartsOver() async {
        let searches = SavedSearches(store: store)
        _ = await searches.refreshAll(using: fetch(["is:pr team": ["A"]]))

        var edited = team
        edited.query = "is:pr team2"
        searches.save(edited)
        #expect(searches.snapshots[team.id] == nil)

        let outcome = await searches.refresh(team.id, using: fetch(["is:pr team2": ["B"]]))
        #expect(outcome.newPullRequests.isEmpty)
    }

    @Test func renamingKeepsTheResults() async {
        let searches = SavedSearches(store: store)
        _ = await searches.refreshAll(using: fetch(["is:pr team": ["A"]]))
        var renamed = team
        renamed.name = "Renamed"
        searches.save(renamed)
        #expect(searches.snapshots[team.id] != nil)
        #expect(store.loadSearches().first?.name == "Renamed")
    }

    @Test func addMoveAndDeleteArePersisted() {
        let searches = SavedSearches(store: store)
        let added = SavedSearch(name: "New", query: "is:pr new")
        searches.save(added)
        searches.move(added.id, by: -1)
        #expect(store.loadSearches().map(\.name) == ["Team", "New", "Quiet"])

        searches.move(team.id, by: -1)
        #expect(store.loadSearches().map(\.name) == ["Team", "New", "Quiet"])

        searches.delete(team.id)
        #expect(store.loadSearches().map(\.name) == ["New", "Quiet"])
    }

    @Test func notifyToggleIsPersisted() {
        let searches = SavedSearches(store: store)
        searches.setNotifies(true, for: quiet.id)
        #expect(store.loadSearches().last?.notifies == true)
    }

    @Test func deletingASearchRemovesItsSnapshot() async {
        let searches = SavedSearches(store: store)
        _ = await searches.refreshAll(using: fetch(["is:pr team": ["A"]]))
        searches.delete(team.id)
        #expect(store.loadSnapshot(for: team.id) == nil)
        #expect(searches.snapshots[team.id] == nil)
    }

    @Test func clearingResultsKeepsTheSearches() async {
        let searches = SavedSearches(store: store)
        _ = await searches.refreshAll(using: fetch(["is:pr team": ["A"]]))
        searches.clearResults()
        #expect(searches.snapshots.isEmpty)
        #expect(store.loadSnapshot(for: team.id) == nil)
        #expect(searches.searches.map(\.name) == ["Team", "Quiet"])

        let outcome = await searches.refreshAll(using: fetch(["is:pr team": ["A", "B"]]))
        #expect(outcome.newPullRequests.isEmpty)
    }

    @Test func unchangedResultsDoNotReloadTheWidget() async {
        let searches = SavedSearches(store: store)
        _ = await searches.refreshAll(using: fetch(["is:pr team": ["A"]]))
        let outcome = await searches.refreshAll(using: fetch(["is:pr team": ["A"]]))
        #expect(!outcome.didChange)
    }
}
