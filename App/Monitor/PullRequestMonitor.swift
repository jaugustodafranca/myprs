import Foundation
import WidgetKit

@MainActor
@Observable
final class PullRequestMonitor {
    static let intervalOptions: [TimeInterval] = [60, 120, 300, 600, 900]

    private(set) var snapshot: PullRequestSnapshot?
    private(set) var isSignedIn: Bool
    private(set) var isRefreshing = false
    private(set) var lastError: String?

    var refreshInterval: TimeInterval {
        didSet {
            defaults.set(refreshInterval, forKey: Self.intervalKey)
            startTimer()
        }
    }

    var pullRequests: [PullRequest] { snapshot?.pullRequests.sortedForDisplay() ?? [] }

    private static let intervalKey = "refreshInterval"

    @ObservationIgnored private let tokenStore = TokenStore()
    @ObservationIgnored private let client = GitHubClient()
    @ObservationIgnored private let snapshotStore = SnapshotStore.shared
    @ObservationIgnored private let notifier = Notifier()
    @ObservationIgnored private let loginFlow = LoginFlow()
    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var timerTask: Task<Void, Never>?

    init() {
        let stored = defaults.double(forKey: Self.intervalKey)
        refreshInterval = Self.intervalOptions.contains(stored) ? stored : 120
        snapshot = snapshotStore.load()
        isSignedIn = tokenStore.load() != nil
        if isSignedIn { startTimer() }
    }

    func signIn() async {
        lastError = nil
        do {
            let token = try await loginFlow.signIn()
            tokenStore.save(token)
            isSignedIn = true
            notifier.requestAuthorization()
            startTimer()
        } catch let error as LoginError {
            lastError = error.errorDescription
        } catch {
            // Dismissing the sign-in sheet is not worth an error message.
        }
    }

    func signOut() {
        timerTask?.cancel()
        tokenStore.delete()
        snapshotStore.clear()
        snapshot = nil
        isSignedIn = false
        lastError = nil
        WidgetCenter.shared.reloadAllTimelines()
    }

    func refresh() async {
        guard let token = tokenStore.load(), !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let fresh = try await client.fetchOpenPullRequests(token: token)
            let changes = ChangeDetector.changes(from: snapshot?.pullRequests ?? [], to: fresh.pullRequests)
            notifier.notify(changes)
            snapshotStore.save(fresh)
            snapshot = fresh
            lastError = nil
            WidgetCenter.shared.reloadAllTimelines()
        } catch GitHubError.unauthorized {
            signOut()
            lastError = "Your GitHub session expired. Sign in again."
        } catch {
            lastError = "Could not refresh. Will retry."
        }
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
