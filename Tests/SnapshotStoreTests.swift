import Foundation
import Testing

@Suite struct SnapshotStoreTests {
    @Test func savedSnapshotIsLoadedBack() throws {
        let store = try makeStoreInTemporaryDirectory()
        let snapshot = PullRequestSnapshot(
            login: "octocat",
            pullRequests: [makePullRequest(checks: .failing, unansweredThreads: 2)],
            fetchedAt: Date(timeIntervalSince1970: 1_700_000_100)
        )

        store.save(snapshot)

        let loaded = try #require(store.load())
        #expect(loaded.login == "octocat")
        #expect(loaded.pullRequests == snapshot.pullRequests)
        #expect(loaded.fetchedAt == snapshot.fetchedAt)
    }

    @Test func loadReturnsNilWhenNothingWasSaved() throws {
        #expect(try makeStoreInTemporaryDirectory().load() == nil)
    }

    @Test func clearRemovesTheSnapshot() throws {
        let store = try makeStoreInTemporaryDirectory()
        store.save(PullRequestSnapshot(login: "octocat", pullRequests: [], fetchedAt: .now))

        store.clear()

        #expect(store.load() == nil)
    }

    private func makeStoreInTemporaryDirectory() throws -> SnapshotStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return SnapshotStore(directory: directory)
    }
}
