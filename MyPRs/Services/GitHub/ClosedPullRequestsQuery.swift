import MyPRsKit

enum ClosedPullRequestsQuery {
    static let pageSize = 20

    static let text = """
    query($after: String) {
      search(query: "is:pr author:@me is:closed archived:false sort:created-desc", type: ISSUE, first: \(pageSize), after: $after) {
        pageInfo { hasNextPage endCursor }
        nodes {
          ... on PullRequest {
            id number title url state mergedAt closedAt createdAt
            additions deletions changedFiles headRefName baseRefName
            repository { nameWithOwner }
            headRepository { nameWithOwner }
          }
        }
      }
    }
    """
}
