import Foundation

/// The saved searches (`saved-searches.json`) and their last results
/// (`snapshots/<search id>.json`) in the App Group container.
public struct SavedSearchStore: Sendable {
    public static let shared = SavedSearchStore(directory: AppGroupContainer.directory)

    let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    private var searchesURL: URL { directory.appendingPathComponent("saved-searches.json") }
    private var snapshotsDirectory: URL { directory.appendingPathComponent("snapshots", isDirectory: true) }

    private func snapshotURL(for searchID: UUID) -> URL {
        snapshotsDirectory.appendingPathComponent("\(searchID.uuidString).json")
    }

    /// Before anything was saved, the list holds the built-in "Review requested" search.
    public func loadSearches() -> [SavedSearch] {
        JSONFile.read([SavedSearch].self, from: searchesURL) ?? [.reviewRequested]
    }

    public func saveSearches(_ searches: [SavedSearch]) {
        JSONFile.write(searches, to: searchesURL)
    }

    public func loadSnapshot(for searchID: UUID) -> SavedSearchSnapshot? {
        JSONFile.read(SavedSearchSnapshot.self, from: snapshotURL(for: searchID))
    }

    public func saveSnapshot(_ snapshot: SavedSearchSnapshot) {
        JSONFile.write(snapshot, to: snapshotURL(for: snapshot.searchID))
    }

    public func removeSnapshot(for searchID: UUID) {
        try? FileManager.default.removeItem(at: snapshotURL(for: searchID))
    }

    public func clearSnapshots() {
        try? FileManager.default.removeItem(at: snapshotsDirectory)
    }
}
