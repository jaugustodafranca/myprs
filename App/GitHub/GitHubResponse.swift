import Foundation

struct GitHubResponse: Decodable {
    let data: DataPayload?
    let errors: [GraphQLError]?

    struct GraphQLError: Decodable {
        let message: String
    }

    struct DataPayload: Decodable {
        let viewer: Viewer
        let search: Search
    }

    struct Viewer: Decodable {
        let login: String
    }

    struct Search: Decodable {
        let nodes: [SearchNode]
    }

    /// Search results that are not pull requests come back as empty objects.
    struct SearchNode: Decodable {
        let pullRequest: PullRequestNode?

        init(from decoder: Decoder) throws {
            pullRequest = try? PullRequestNode(from: decoder)
        }
    }

    struct PullRequestNode: Decodable {
        let id: String
        let number: Int
        let title: String
        let url: URL
        let isDraft: Bool
        let updatedAt: Date
        let createdAt: Date
        let additions: Int
        let deletions: Int
        let changedFiles: Int
        let headRefName: String
        let baseRefName: String
        let mergeable: String
        let reviewDecision: String?
        let repository: Repository
        let commits: Connection<CommitNode>
        let latestReviews: Connection<Review>
        let reviewThreads: Connection<ReviewThread>
    }

    struct Repository: Decodable {
        let nameWithOwner: String
    }

    struct Connection<Node: Decodable>: Decodable {
        let nodes: [Node]
    }

    struct CommitNode: Decodable {
        let commit: Commit
    }

    struct Commit: Decodable {
        let statusCheckRollup: StatusCheckRollup?
    }

    struct StatusCheckRollup: Decodable {
        let state: String
        let contexts: Connection<CheckContext>
    }

    /// A `CheckRun` has `conclusion`; a `StatusContext` has `state`.
    struct CheckContext: Decodable {
        let conclusion: String?
        let state: String?
    }

    struct Review: Decodable {
        let state: String
    }

    struct ReviewThread: Decodable {
        let isResolved: Bool
        let comments: Connection<Comment>
    }

    struct Comment: Decodable {
        let author: Author?
    }

    struct Author: Decodable {
        let login: String
    }
}
