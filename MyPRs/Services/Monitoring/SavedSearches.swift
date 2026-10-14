import Foundation
import MyPRsKit

/// The saved searches and their latest results, persisted per search for the widget.
@MainActor
@Observable
final class SavedSearches {
    typealias Fetch = (_ query: String) async throws -> [PullRequest]

    private(set) var searches: [SavedSearch]
    private(set) var snapshots: [UUID: SavedSearchSnapshot] = [:]
    private(set) var failedSearchIDs: Set<UUID> = []

    @ObservationIgnored private let store: SavedSearchStore
    /// Results fetched during this run of the app: the baseline for "new" pull requests.
    @ObservationIgnored private var fetchedIDs: [UUID: Set<String>] = [:]
    @ObservationIgnored private var generation = 0

    init(store: SavedSearchStore) {
        self.store = store
        searches = store.loadSearches()
        for search in searches {
            snapshots[search.id] = store.loadSnapshot(for: search.id)
        }
    }

    func search(withID id: UUID) -> SavedSearch? {
        searches.first { $0.id == id }
    }

    // MARK: Fetching

    func refreshAll(using fetch: Fetch) async -> SavedSearchRefresh {
        var outcome = SavedSearchRefresh()
        for search in searches {
            merge(await refresh(search, using: fetch), into: &outcome)
        }
        return outcome
    }

    func refresh(_ id: UUID, using fetch: Fetch) async -> SavedSearchRefresh {
        guard let search = search(withID: id) else { return SavedSearchRefresh() }
        return await refresh(search, using: fetch)
    }

    private func refresh(_ search: SavedSearch, using fetch: Fetch) async -> SavedSearchRefresh {
        let startedIn = generation
        do {
            let pullRequests = try await fetch(search.query)
            guard startedIn == generation, self.search(withID: search.id)?.query == search.query else { return SavedSearchRefresh() }
            return record(pullRequests, for: search)
        } catch {
            guard startedIn == generation, self.search(withID: search.id) != nil else { return SavedSearchRefresh() }
            failedSearchIDs.insert(search.id)
            return SavedSearchRefresh()
        }
    }

    private func record(_ pullRequests: [PullRequest], for search: SavedSearch) -> SavedSearchRefresh {
        let current = self.search(withID: search.id) ?? search
        let newPullRequests = NewPullRequestDetector.newPullRequests(previous: fetchedIDs[search.id], current: pullRequests)
        let didChange = snapshots[search.id]?.pullRequests != pullRequests
        let snapshot = SavedSearchSnapshot(searchID: search.id, pullRequests: pullRequests, fetchedAt: .now)

        fetchedIDs[search.id] = Set(pullRequests.map(\.id))
        failedSearchIDs.remove(search.id)
        snapshots[search.id] = snapshot
        store.saveSnapshot(snapshot)
        return SavedSearchRefresh(newPullRequests: current.notifies ? newPullRequests : [], didChange: didChange)
    }

    private func merge(_ refresh: SavedSearchRefresh, into outcome: inout SavedSearchRefresh) {
        let known = Set(outcome.newPullRequests.map(\.id))
        outcome.newPullRequests += refresh.newPullRequests.filter { !known.contains($0.id) }
        outcome.didChange = outcome.didChange || refresh.didChange
    }

    // MARK: Editing

    /// Adds the search, or replaces the one with the same id. A changed query starts over:
    /// its old results are dropped and its first new result never notifies.
    func save(_ search: SavedSearch) {
        guard let index = searches.firstIndex(where: { $0.id == search.id }) else {
            searches.append(search)
            persistSearches()
            return
        }
        if searches[index].query != search.query { forgetResults(of: search.id) }
        searches[index] = search
        persistSearches()
    }

    func setNotifies(_ notifies: Bool, for id: UUID) {
        guard var search = search(withID: id) else { return }
        search.notifies = notifies
        save(search)
    }

    func delete(_ id: UUID) {
        searches.removeAll { $0.id == id }
        forgetResults(of: id)
        persistSearches()
    }

    func move(_ id: UUID, by offset: Int) {
        guard let index = searches.firstIndex(where: { $0.id == id }) else { return }
        let destination = index + offset
        guard searches.indices.contains(destination) else { return }
        searches.swapAt(index, destination)
        persistSearches()
    }

    /// Signing out drops every result but keeps the searches.
    func clearResults() {
        generation += 1
        snapshots = [:]
        failedSearchIDs = []
        fetchedIDs = [:]
        store.clearSnapshots()
    }

    private func forgetResults(of id: UUID) {
        snapshots[id] = nil
        failedSearchIDs.remove(id)
        fetchedIDs[id] = nil
        store.removeSnapshot(for: id)
    }

    private func persistSearches() {
        store.saveSearches(searches)
    }
}
