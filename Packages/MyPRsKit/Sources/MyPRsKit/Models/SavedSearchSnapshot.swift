import Foundation

/// The last result of one saved search, shared with the widget.
public struct SavedSearchSnapshot: Codable, Sendable, Equatable {
    public let searchID: UUID
    public let pullRequests: [PullRequest]
    public let fetchedAt: Date

    public init(searchID: UUID, pullRequests: [PullRequest], fetchedAt: Date) {
        self.searchID = searchID
        self.pullRequests = pullRequests
        self.fetchedAt = fetchedAt
    }
}
