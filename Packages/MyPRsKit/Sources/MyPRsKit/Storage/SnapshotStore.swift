import Foundation

public struct SnapshotStore: Sendable {
    public static let shared = SnapshotStore(directory: appGroupDirectory)

    private static var appGroupDirectory: URL {
        // Unsigned builds (CI, tests) have no App Group container.
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConfig.appGroupID)
            ?? FileManager.default.temporaryDirectory
    }

    let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    private var fileURL: URL { directory.appendingPathComponent("snapshot.json") }

    public func load() -> PullRequestSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? Self.decoder.decode(PullRequestSnapshot.self, from: data)
    }

    public func save(_ snapshot: PullRequestSnapshot) {
        guard let data = try? Self.encoder.encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }

    public func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
