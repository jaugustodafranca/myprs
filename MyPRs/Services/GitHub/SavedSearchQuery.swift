/// Runs a saved search. `ISSUE_ADVANCED` accepts AND, OR and parentheses.
enum SavedSearchQuery {
    static let text = """
    query($q: String!) {
      viewer { login }
      search(query: $q, type: ISSUE_ADVANCED, first: 50) {
        nodes { ...PullRequestFields }
      }
    }
    """ + "\n" + PullRequestFields.fragment
}
