import AppKit
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
    private(set) var signOutError: String?
    let revocations = TokenRevocations()
    private(set) var organizationAccess = OrganizationAccess()
    private(set) var notificationPermission = NotificationPermission.unknown

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
    @ObservationIgnored private let recentSnapshotStore = RecentSnapshotStore.shared
    @ObservationIgnored private let notifier = Notifier.shared
    @ObservationIgnored private let loginFlow = LoginFlow.shared
    @ObservationIgnored private let authWorker = AuthWorker()
    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var timerTask: Task<Void, Never>?
    @ObservationIgnored private var sessionGeneration = 0
    @ObservationIgnored private var lastOrganizationCheck: Date?

    init() {
        let client = self.client
        let tokenStore = self.tokenStore
        let recentSnapshotStore = RecentSnapshotStore.shared
        recent = RecentPullRequests(fetchPage: { cursor in
            guard let token = tokenStore.load() else { throw GitHubError.unauthorized }
            return try await client.fetchClosedPullRequests(token: token, after: cursor)
        }, onChange: { items, fetchedAt in
            recentSnapshotStore.save(ClosedPullRequestSnapshot(pullRequests: items, fetchedAt: fetchedAt))
            WidgetCenter.shared.reloadTimelines(ofKind: AppConfig.widgetKind)
        })
        refreshInterval = RefreshInterval.restored(from: defaults.double(forKey: Self.intervalKey))
        snapshot = snapshotStore.load()
        isSignedIn = tokenStore.load() != nil
        WidgetCenter.shared.reloadTimelines(ofKind: AppConfig.widgetKind)
        if isSignedIn {
            startTimer()
            Task { await requestNotificationsIfNeeded() }
        }
    }

    func signIn() async {
        guard !isSignedIn, !isSigningIn else { return }
        let generation = sessionGeneration
        lastError = nil
        isSigningIn = true
        defer { isSigningIn = false }
        do {
            let token = try await loginFlow.signIn()
            guard generation == sessionGeneration else {
                revocations.start(token: token, worker: authWorker)
                return
            }
            try storeOrRevoke(token)
            isSignedIn = true
            startTimer()
            Task { await requestNotificationsIfNeeded() }
        } catch let error as LoginError {
            guard generation == sessionGeneration else { return }
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
            revocations.start(token: token, worker: authWorker)
            throw error
        }
    }

    func cancelSignIn() {
        sessionGeneration += 1
        loginFlow.cancel()
    }

    func signOut() {
        disconnect(revoke: true)
    }

    private func disconnect(revoke: Bool) {
        do {
            let token = revoke ? try tokenStore.read() : nil
            try tokenStore.delete()
            if let token {
                revocations.start(token: token, worker: authWorker)
            }
        } catch {
            signOutError = error.localizedDescription
            return
        }
        signOutError = nil
        sessionGeneration += 1
        timerTask?.cancel()
        isRefreshing = false
        notifier.clear()
        snapshotStore.clear()
        recentSnapshotStore.clear()
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
        guard isSignedIn, !isRefreshing, let token = tokenStore.load() else { return }
        let generation = sessionGeneration
        isRefreshing = true
        defer { if generation == sessionGeneration { isRefreshing = false } }

        do {
            try await refreshOpenPullRequests(token: token, generation: generation)
        } catch GitHubError.unauthorized {
            guard generation == sessionGeneration else { return }
            disconnect(revoke: false)
            lastError = signOutError ?? "Your GitHub session expired. Sign in again."
            return
        } catch {
            guard generation == sessionGeneration else { return }
            lastError = "Could not refresh. Will retry."
        }
        guard generation == sessionGeneration else { return }
        await recent.loadIfNeeded()
        guard generation == sessionGeneration else { return }
        let searches = await savedSearches.refreshAll(using: searchFetcher(token: token))
        guard generation == sessionGeneration else { return }
        apply(searches)
        if lastError == nil { await checkOrganizationAccess(token: token) }
        await checkNotificationPermission()
    }

    // MARK: Notifications

    /// Reads what macOS currently allows; the user may have changed it in System Settings.
    func checkNotificationPermission() async {
        notificationPermission = NotificationPermission(await notifier.authorizationStatus())
    }

    /// Shows the system prompt if it was never answered, else opens the app's entry in System Settings.
    func allowNotifications() async {
        await checkNotificationPermission()
        if notificationPermission.canAsk {
            await requestNotifications()
        } else {
            NSWorkspace.shared.open(NotificationPermission.systemSettingsURL(bundleID: Bundle.main.bundleIdentifier ?? ""))
        }
    }

    private func requestNotificationsIfNeeded() async {
        await checkNotificationPermission()
        if notificationPermission.canAsk { await requestNotifications() }
    }

    private func requestNotifications() async {
        await notifier.requestAuthorization()
        await checkNotificationPermission()
    }

    private func refreshOpenPullRequests(token: String, generation: Int) async throws {
        let fresh = try await client.fetchOpenPullRequests(token: token)
        guard generation == sessionGeneration else { return }
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
        guard isSignedIn, let token = tokenStore.load() else { return }
        let generation = sessionGeneration
        let result = await savedSearches.refresh(id, using: searchFetcher(token: token))
        guard generation == sessionGeneration else { return }
        apply(result)
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
        let generation = sessionGeneration
        guard let access = try? await client.fetchOrganizationAccess(token: token), generation == sessionGeneration else { return }
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
