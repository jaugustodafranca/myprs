import Foundation

struct PullRequest: Codable, Hashable, Identifiable {
    let id: String
    let number: Int
    let title: String
    let url: URL
    let repository: String
    let isDraft: Bool
    let checks: CheckStatus
    let review: ReviewStatus
    let unansweredThreads: Int
    let updatedAt: Date
    let createdAt: Date
    let additions: Int
    let deletions: Int
    let changedFiles: Int
    let headBranch: String
    let baseBranch: String
    let hasConflicts: Bool
    let checksPassed: Int
    let checksTotal: Int
    let approvals: Int

    var needsAttention: Bool { checks == .failing || unansweredThreads > 0 }
}

enum CheckStatus: String, Codable {
    case passing, failing, running, none
}

enum ReviewStatus: String, Codable {
    case approved, changesRequested, waiting
}
