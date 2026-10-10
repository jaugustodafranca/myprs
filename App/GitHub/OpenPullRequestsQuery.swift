enum OpenPullRequestsQuery {
    static let text = """
    query {
      viewer { login }
      search(query: "is:pr is:open author:@me archived:false", type: ISSUE, first: 50) {
        nodes {
          ... on PullRequest {
            id number title url isDraft updatedAt reviewDecision
            repository { nameWithOwner }
            commits(last: 1) { nodes { commit { statusCheckRollup { state } } } }
            reviewThreads(first: 100) {
              nodes { isResolved comments(last: 1) { nodes { author { login } } } }
            }
          }
        }
      }
    }
    """
}
