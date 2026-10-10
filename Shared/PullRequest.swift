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

    var needsAttention: Bool { checks == .failing || unansweredThreads > 0 }
}

enum CheckStatus: String, Codable {
    case passing, failing, running, none
}

enum ReviewStatus: String, Codable {
    case approved, changesRequested, waiting
}
