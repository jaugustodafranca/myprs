import Foundation

public struct ClosedPullRequest: Codable, Hashable, Identifiable, GroupablePullRequest, Sendable {
    public let id: String
    public let number: Int
    public let title: String
    public let url: URL
    public let repository: String
    public let headRepository: String?
    public let headBranch: String
    public let baseBranch: String
    public let state: ClosedState
    public let createdAt: Date
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
        changedFiles: Int,
        createdAt: Date = .distantPast,
        headRepository: String? = nil
    ) {
        self.id = id
        self.number = number
        self.title = title
        self.url = url
        self.repository = repository
        self.headRepository = headRepository
        self.headBranch = headBranch
        self.baseBranch = baseBranch
        self.state = state
        self.createdAt = createdAt
        self.endedAt = endedAt
        self.additions = additions
        self.deletions = deletions
        self.changedFiles = changedFiles
    }
}
