import MyPRsKit

enum NewPullRequestDetector {
    /// Pull requests in `current` that were not in `previous`. Without a previous
    /// result (first load of a search, or after launch) nothing is new.
    static func newPullRequests(previous: Set<String>?, current: [PullRequest]) -> [PullRequest] {
        guard let previous else { return [] }
        return current.filter { !previous.contains($0.id) }
    }
}
