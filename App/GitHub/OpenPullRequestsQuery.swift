enum OpenPullRequestsQuery {
    static let text = """
    query {
      viewer { login }
      search(query: "is:pr is:open author:@me archived:false", type: ISSUE, first: 50) {
        nodes {
          ... on PullRequest {
            id number title url isDraft updatedAt createdAt reviewDecision
            additions deletions changedFiles headRefName baseRefName mergeable
            repository { nameWithOwner }
            latestReviews(first: 20) { nodes { state } }
            commits(last: 1) {
              nodes {
                commit {
                  statusCheckRollup {
                    state
                    contexts(first: 100) {
                      nodes {
                        __typename
                        ... on CheckRun { status conclusion }
                        ... on StatusContext { state }
                      }
                    }
                  }
                }
              }
            }
            reviewThreads(first: 100) {
              nodes { isResolved comments(last: 1) { nodes { author { login } } } }
            }
          }
        }
      }
    }
    """
}
