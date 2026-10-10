import Foundation

struct PullRequestSnapshot: Codable {
    let login: String
    let pullRequests: [PullRequest]
    let fetchedAt: Date
}
