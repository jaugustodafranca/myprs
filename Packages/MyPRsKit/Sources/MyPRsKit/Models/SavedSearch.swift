import Foundation

/// A GitHub search whose pull requests are listed in the Review tab.
public struct SavedSearch: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var query: String
    public var notifies: Bool

    public init(id: UUID = UUID(), name: String, query: String, notifies: Bool = false) {
        self.id = id
        self.name = name
        self.query = query
        self.notifies = notifies
    }

    public static let reviewRequested = SavedSearch(
        name: "Review requested",
        query: "is:pr is:open archived:false review-requested:@me"
    )
}
