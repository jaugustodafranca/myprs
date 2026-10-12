import Foundation
@testable import MyPRsKit
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

    @Test func loadReturnsNilForSnapshotInOldFormat() throws {
        let directory = try makeTemporaryDirectory()
        try Data(oldFormatSnapshot.utf8).write(to: directory.appendingPathComponent("snapshot.json"))

        #expect(SnapshotStore(directory: directory).load() == nil)
    }

    private func makeStoreInTemporaryDirectory() throws -> SnapshotStore {
        SnapshotStore(directory: try makeTemporaryDirectory())
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

private let oldFormatSnapshot = """
{
  "login": "octocat",
  "fetchedAt": "2026-09-30T08:00:00Z",
  "pullRequests": [
    {
      "id": "PR_1", "number": 1, "title": "Old", "url": "https://github.com/acme/web/pull/1",
      "repository": "acme/web", "isDraft": false, "checks": "passing", "review": "waiting",
      "unansweredThreads": 0, "updatedAt": "2026-09-30T08:00:00Z"
    }
  ]
}
"""
