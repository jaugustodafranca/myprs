import Foundation
import MyPRsKit
import WidgetKit

@MainActor
@Observable
final class PullRequestMonitor {
    private(set) var snapshot: PullRequestSnapshot?
    private(set) var isSignedIn: Bool
    private(set) var isRefreshing = false
    private(set) var isSigningIn = false
    private(set) var lastError: String?
    private(set) var organizationAccess = OrganizationAccess()

    var refreshInterval: TimeInterval {
        didSet {
            defaults.set(refreshInterval, forKey: Self.intervalKey)
            startTimer()
        }
    }

    let recent: RecentPullRequests
    let savedSearches = SavedSearches(store: .shared)

    var pullRequests: [PullRequest] { snapshot?.pullRequests.sortedForDisplay() ?? [] }

    private static let intervalKey = "refreshInterval"
    private static let organizationCheckInterval: TimeInterval = 30 * 60

    @ObservationIgnored private let tokenStore = TokenStore()
    @ObservationIgnored private let client = GitHubClient()
    @ObservationIgnored private let snapshotStore = SnapshotStore.shared
    @ObservationIgnored private let notifier = Notifier()
    @ObservationIgnored private let loginFlow = LoginFlow.shared
    @ObservationIgnored private let authWorker = AuthWorker()
    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var timerTask: Task<Void, Never>?
    @ObservationIgnored private var lastOrganizationCheck: Date?

    init() {
        let client = self.client
        let tokenStore = self.tokenStore
        recent = RecentPullRequests { cursor in
            guard let token = tokenStore.load() else { throw GitHubError.unauthorized }
            return try await client.fetchClosedPullRequests(token: token, after: cursor)
        }
        refreshInterval = RefreshInterval.restored(from: defaults.double(forKey: Self.intervalKey))
        snapshot = snapshotStore.load()
        isSignedIn = tokenStore.load() != nil
        WidgetCenter.shared.reloadTimelines(ofKind: AppConfig.widgetKind)
        if isSignedIn {
            notifier.requestAuthorization()
            startTimer()
        }
    }

    func signIn() async {
        guard !isSigningIn else { return }
        lastError = nil
        isSigningIn = true
        defer { isSigningIn = false }
        do {
            let token = try await loginFlow.signIn()
            try storeOrRevoke(token)
            isSignedIn = true
            notifier.requestAuthorization()
            startTimer()
        } catch let error as LoginError {
            lastError = error.errorDescription
        } catch let error as TokenStoreError {
            lastError = error.errorDescription
        } catch {
            // Cancelling a sign-in is not worth an error message.
        }
    }

    /// A token the Keychain refused would be an orphaned grant, so it is revoked.
    private func storeOrRevoke(_ token: String) throws {
        do {
            try tokenStore.save(token)
        } catch {
            revokeInBackground(token)
            throw error
        }
    }

    private func revokeInBackground(_ token: String) {
        let authWorker = self.authWorker
        Task { await authWorker.revoke(token) }
    }

    func cancelSignIn() {
        loginFlow.cancel()
    }

    func signOut() {
        timerTask?.cancel()
        if let token = tokenStore.load() { revokeInBackground(token) }
        tokenStore.delete()
        snapshotStore.clear()
        recent.clear()
        savedSearches.clearResults()
        snapshot = nil
        organizationAccess = OrganizationAccess()
        lastOrganizationCheck = nil
        isSignedIn = false
        lastError = nil
        WidgetCenter.shared.reloadTimelines(ofKind: AppConfig.widgetKind)
    }

    func refresh() async {
        guard let token = tokenStore.load(), !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            try await refreshOpenPullRequests(token: token)
        } catch GitHubError.unauthorized {
            signOut()
            lastError = "Your GitHub session expired. Sign in again."
            return
        } catch {
            lastError = "Could not refresh. Will retry."
        }
        guard isSignedIn else { return }
        apply(await savedSearches.refreshAll(using: searchFetcher(token: token)))
        if lastError == nil { await checkOrganizationAccess(token: token) }
    }

    private func refreshOpenPullRequests(token: String) async throws {
        let fresh = try await client.fetchOpenPullRequests(token: token)
        guard isSignedIn else { return }
        let changes = ChangeDetector.changes(from: snapshot?.pullRequests ?? [], to: fresh.pullRequests)
        notifier.notify(changes)
        let pullRequestsChanged = snapshot?.pullRequests != fresh.pullRequests
        snapshotStore.save(fresh)
        snapshot = fresh
        lastError = nil
        if pullRequestsChanged {
            WidgetCenter.shared.reloadTimelines(ofKind: AppConfig.widgetKind)
        }
    }

    /// Saves an added or edited search and fetches it right away.
    func saveSearch(_ search: SavedSearch) async {
        savedSearches.save(search)
        await refreshSearch(search.id)
    }

    func refreshSearch(_ id: UUID) async {
        guard let token = tokenStore.load() else { return }
        apply(await savedSearches.refresh(id, using: searchFetcher(token: token)))
    }

    func deleteSearch(_ id: UUID) {
        savedSearches.delete(id)
        WidgetCenter.shared.reloadTimelines(ofKind: AppConfig.widgetKind)
    }

    private func searchFetcher(token: String) -> SavedSearches.Fetch {
        let client = self.client
        return { query in try await client.fetchPullRequests(matching: query, token: token) }
    }

    private func apply(_ refresh: SavedSearchRefresh) {
        guard isSignedIn else { return }
        notifier.notifyNewToReview(refresh.newPullRequests)
        if refresh.didChange {
            WidgetCenter.shared.reloadTimelines(ofKind: AppConfig.widgetKind)
        }
    }

    func checkOrganizationAccess(force: Bool = false) async {
        guard let token = tokenStore.load() else { return }
        await checkOrganizationAccess(token: token, force: force)
    }

    private func checkOrganizationAccess(token: String, force: Bool = false) async {
        if !force, let last = lastOrganizationCheck, Date().timeIntervalSince(last) < Self.organizationCheckInterval { return }
        guard let access = try? await client.fetchOrganizationAccess(token: token), isSignedIn else { return }
        lastOrganizationCheck = Date()
        organizationAccess = access
    }

    func signInAgain() async {
        signOut()
        await signIn()
    }

    private func startTimer() {
        timerTask?.cancel()
        guard isSignedIn else { return }
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                guard let interval = self?.refreshInterval else { return }
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }
}
