import MyPRsKit

struct SavedSearchRefresh {
    /// New pull requests of searches that notify, each pull request once.
    var newPullRequests: [PullRequest] = []
    var didChange = false
}
