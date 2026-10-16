import Foundation

public struct ClosedPullRequestSnapshot: Codable, Sendable {
    public let pullRequests: [ClosedPullRequest]
    public let fetchedAt: Date

    public init(pullRequests: [ClosedPullRequest], fetchedAt: Date) {
        self.pullRequests = pullRequests
        self.fetchedAt = fetchedAt
    }
}
