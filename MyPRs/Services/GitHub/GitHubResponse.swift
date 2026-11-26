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
        let author: PullRequestAuthor?
        let repository: Repository
        let headRepository: Repository?
        let commits: Connection<CommitNode>
        let latestReviews: Connection<Review>
        let reviewThreads: Connection<ReviewThread>
    }

    struct PullRequestAuthor: Decodable {
        let login: String
        let avatarUrl: URL?
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
        let oid: String
        let statusCheckRollup: StatusCheckRollup?
    }

    struct StatusCheckRollup: Decodable {
        let contexts: CheckPage
    }

    struct CheckPage: Decodable {
        let nodes: [CheckContext]
        let pageInfo: PageInfo
    }

    struct PageInfo: Decodable {
        let hasNextPage: Bool
        let endCursor: String?
    }

    struct CheckContext: Decodable {
        let name: String?
        let status: String?
        let conclusion: String?
        let startedAt: Date?
        let completedAt: Date?
        let checkSuite: CheckSuite?
        let context: String?
        let state: String?
        let description: String?
        let createdAt: Date?
    }

    struct CheckSuite: Decodable {
        let workflowRun: WorkflowRun?
    }

    struct WorkflowRun: Decodable {
        let databaseId: Int64
        let createdAt: Date
        let event: String
        let workflow: Workflow
    }

    struct Workflow: Decodable {
        let name: String
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
