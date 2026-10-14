import Foundation

public struct SnapshotStore: Sendable {
    public static let shared = SnapshotStore(directory: AppGroupContainer.directory)

    let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    private var fileURL: URL { directory.appendingPathComponent("snapshot.json") }

    public func load() -> PullRequestSnapshot? {
        JSONFile.read(PullRequestSnapshot.self, from: fileURL)
    }

    public func save(_ snapshot: PullRequestSnapshot) {
        JSONFile.write(snapshot, to: fileURL)
    }

    public func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
