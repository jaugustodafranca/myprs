import Foundation

struct ClosedPullRequestsResponse: Decodable {
    let data: DataPayload?
    let errors: [GraphQLError]?

    struct GraphQLError: Decodable {
        let message: String
    }

    struct DataPayload: Decodable {
        let search: Search
    }

    struct Search: Decodable {
        let pageInfo: PageInfo
        let nodes: [SearchNode]
    }

    struct PageInfo: Decodable {
        let hasNextPage: Bool
        let endCursor: String?
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
        let state: String
        let mergedAt: Date?
        let closedAt: Date?
        let additions: Int
        let deletions: Int
        let changedFiles: Int
        let headRefName: String
        let baseRefName: String
        let repository: Repository
    }

    struct Repository: Decodable {
        let nameWithOwner: String
    }
}
