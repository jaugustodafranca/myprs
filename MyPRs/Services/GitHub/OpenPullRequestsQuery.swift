enum OpenPullRequestsQuery {
    static let text = """
    query {
      viewer { login }
      search(query: "is:pr is:open author:@me archived:false", type: ISSUE, first: 50) {
        nodes { ...PullRequestFields }
      }
    }
    """ + "\n" + PullRequestFields.fragment
}
