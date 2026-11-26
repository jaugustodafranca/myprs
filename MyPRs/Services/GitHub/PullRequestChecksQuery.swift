enum PullRequestChecksQuery {
    static let text = """
    query($owner: String!, $name: String!, $number: Int!, $after: String) {
      repository(owner: $owner, name: $name) {
        pullRequest(number: $number) {
          mergeStateStatus
          commits(last: 1) { nodes { commit {
            oid
            statusCheckRollup {
              contexts(first: 100, after: $after) {
                totalCount
                pageInfo { hasNextPage endCursor }
                nodes {
                  __typename
                  ... on CheckRun {
                    name status conclusion startedAt completedAt databaseId
                    isRequired(pullRequestNumber: $number)
                    checkSuite { createdAt workflowRun { id databaseId runNumber event createdAt workflow { name } } }
                  }
                  ... on StatusContext {
                    context state description createdAt isRequired(pullRequestNumber: $number)
                  }
                }
              }
            }
          } } }
        }
      }
    }
    """
}

struct PullRequestChecksResponse: Decodable {
    let data: Payload?
    let errors: [GitHubResponse.GraphQLError]?

    struct Payload: Decodable {
        let repository: Repository?
    }

    struct Repository: Decodable {
        let pullRequest: PullRequest?
    }

    struct PullRequest: Decodable {
        let mergeStateStatus: String
        let commits: GitHubResponse.Connection<GitHubResponse.CommitNode>
    }
}
