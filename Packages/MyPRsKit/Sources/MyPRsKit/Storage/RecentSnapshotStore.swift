import Foundation

public struct RecentSnapshotStore: Sendable {
    public static let shared = RecentSnapshotStore(directory: AppGroupContainer.directory)

    let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    private var fileURL: URL { directory.appendingPathComponent("recent-snapshot.json") }

    public func load() -> ClosedPullRequestSnapshot? {
        JSONFile.read(ClosedPullRequestSnapshot.self, from: fileURL)
    }

    public func save(_ snapshot: ClosedPullRequestSnapshot) {
        JSONFile.write(snapshot, to: fileURL)
    }

    public func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
