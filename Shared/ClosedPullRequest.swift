import Foundation

struct ClosedPullRequest: Hashable, Identifiable {
    let id: String
    let number: Int
    let title: String
    let url: URL
    let repository: String
    let headBranch: String
    let baseBranch: String
    let state: ClosedState
    let endedAt: Date
    let additions: Int
    let deletions: Int
    let changedFiles: Int
}

enum ClosedState {
    case merged, closed
}

struct ClosedPullRequestPage {
    let pullRequests: [ClosedPullRequest]
    let endCursor: String?
    let hasNextPage: Bool
}
