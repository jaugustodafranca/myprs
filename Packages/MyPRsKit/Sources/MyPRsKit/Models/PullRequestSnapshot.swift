import Foundation

public struct PullRequestSnapshot: Codable, Sendable {
    public let login: String
    public let pullRequests: [PullRequest]
    public let fetchedAt: Date

    public init(login: String, pullRequests: [PullRequest], fetchedAt: Date) {
        self.login = login
        self.pullRequests = pullRequests
        self.fetchedAt = fetchedAt
    }
}
