import Foundation

/// Stands in for the real monitor, which polls GitHub and reads the Keychain.
/// It holds what the views read; every action does nothing.
@MainActor
@Observable
final class PullRequestMonitor {
    var snapshot: PullRequestSnapshot?
    var isSignedIn = true
    var isRefreshing = false
    var isSigningIn = false
    var lastError: String?
    var organizationAccess = OrganizationAccess()
    var refreshInterval = RefreshInterval.standard

    let recent: RecentPullRequests
    let savedSearches: SavedSearches

    var pullRequests: [PullRequest] { snapshot?.pullRequests.sortedForDisplay() ?? [] }

    init(snapshot: PullRequestSnapshot?, recent: RecentPullRequests, savedSearches: SavedSearches) {
        self.snapshot = snapshot
        self.recent = recent
        self.savedSearches = savedSearches
    }

    func signIn() async {}
    func signInAgain() async {}
    func cancelSignIn() {}
    func signOut() {}
    func refresh() async {}
    func refreshSearch(_ id: UUID) async {}
    func saveSearch(_ search: SavedSearch) async {}
    func deleteSearch(_ id: UUID) {}
    func checkOrganizationAccess(force: Bool = false) async {}
}

/// Stands in for the Sparkle-backed updater.
@MainActor
@Observable
final class Updater {
    var canCheckForUpdates = true

    func checkForUpdates() {}
}
