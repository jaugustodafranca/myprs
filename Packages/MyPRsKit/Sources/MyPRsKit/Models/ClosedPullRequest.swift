import Foundation

public struct ClosedPullRequest: Hashable, Identifiable, Sendable {
    public let id: String
    public let number: Int
    public let title: String
    public let url: URL
    public let repository: String
    public let headBranch: String
    public let baseBranch: String
    public let state: ClosedState
    public let endedAt: Date
    public let additions: Int
    public let deletions: Int
    public let changedFiles: Int

    public init(
        id: String,
        number: Int,
        title: String,
        url: URL,
        repository: String,
        headBranch: String,
        baseBranch: String,
        state: ClosedState,
        endedAt: Date,
        additions: Int,
        deletions: Int,
        changedFiles: Int
    ) {
        self.id = id
        self.number = number
        self.title = title
        self.url = url
        self.repository = repository
        self.headBranch = headBranch
        self.baseBranch = baseBranch
        self.state = state
        self.endedAt = endedAt
        self.additions = additions
        self.deletions = deletions
        self.changedFiles = changedFiles
    }
}

public enum ClosedState: Sendable {
    case merged, closed
}

public struct ClosedPullRequestPage: Sendable {
    public let pullRequests: [ClosedPullRequest]
    public let endCursor: String?
    public let hasNextPage: Bool

    public init(pullRequests: [ClosedPullRequest], endCursor: String?, hasNextPage: Bool) {
        self.pullRequests = pullRequests
        self.endCursor = endCursor
        self.hasNextPage = hasNextPage
    }
}
