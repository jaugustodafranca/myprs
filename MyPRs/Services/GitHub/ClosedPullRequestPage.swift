import Foundation

struct ClosedPullRequestPage: Sendable {
    let pullRequests: [ClosedPullRequest]
    let endCursor: String?
    let hasNextPage: Bool

    init(pullRequests: [ClosedPullRequest], endCursor: String?, hasNextPage: Bool) {
        self.pullRequests = pullRequests
        self.endCursor = endCursor
        self.hasNextPage = hasNextPage
    }
}
