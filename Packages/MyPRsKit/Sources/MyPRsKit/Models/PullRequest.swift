import Foundation

public struct PullRequest: Codable, Hashable, Identifiable, Sendable {
    public let id: String
    public let number: Int
    public let title: String
    public let url: URL
    public let repository: String
    public let isDraft: Bool
    public let checks: CheckStatus
    public let review: ReviewStatus
    public let unansweredThreads: Int
    public let updatedAt: Date
    public let createdAt: Date
    public let additions: Int
    public let deletions: Int
    public let changedFiles: Int
    public let headBranch: String
    public let baseBranch: String
    public let hasConflicts: Bool
    public let checksPassed: Int
    public let checksTotal: Int
    public let approvals: Int
    /// Nil in snapshots saved before authors were fetched.
    public let authorLogin: String?
    public let authorAvatarURL: URL?

    public var needsAttention: Bool { checks == .failing || unansweredThreads > 0 }

    public init(
        id: String,
        number: Int,
        title: String,
        url: URL,
        repository: String,
        isDraft: Bool,
        checks: CheckStatus,
        review: ReviewStatus,
        unansweredThreads: Int,
        updatedAt: Date,
        createdAt: Date,
        additions: Int,
        deletions: Int,
        changedFiles: Int,
        headBranch: String,
        baseBranch: String,
        hasConflicts: Bool,
        checksPassed: Int,
        checksTotal: Int,
        approvals: Int,
        authorLogin: String? = nil,
        authorAvatarURL: URL? = nil
    ) {
        self.id = id
        self.number = number
        self.title = title
        self.url = url
        self.repository = repository
        self.isDraft = isDraft
        self.checks = checks
        self.review = review
        self.unansweredThreads = unansweredThreads
        self.updatedAt = updatedAt
        self.createdAt = createdAt
        self.additions = additions
        self.deletions = deletions
        self.changedFiles = changedFiles
        self.headBranch = headBranch
        self.baseBranch = baseBranch
        self.hasConflicts = hasConflicts
        self.checksPassed = checksPassed
        self.checksTotal = checksTotal
        self.approvals = approvals
        self.authorLogin = authorLogin
        self.authorAvatarURL = authorAvatarURL
    }
}
