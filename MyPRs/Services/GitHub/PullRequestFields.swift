/// The pull request fields every list query asks for, as a GraphQL fragment.
enum PullRequestFields {
    static let fragment = """
    fragment PullRequestFields on PullRequest {
      id number title url isDraft updatedAt createdAt reviewDecision
      additions deletions changedFiles headRefName baseRefName mergeable
      author { login avatarUrl }
      repository { nameWithOwner }
      headRepository { nameWithOwner }
      latestReviews(first: 20) { nodes { state } }
      commits(last: 1) {
        nodes {
          commit {
            statusCheckRollup {
              state
              contexts(first: 100) {
                nodes {
                  ... on CheckRun { conclusion }
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
    """
}
