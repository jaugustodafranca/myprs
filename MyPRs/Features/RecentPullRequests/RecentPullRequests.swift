import Foundation
import MyPRsKit

@MainActor
@Observable
final class RecentPullRequests {
    typealias FetchPage = (_ cursor: String?) async throws -> ClosedPullRequestPage

    static let staleAfter: TimeInterval = 10 * 60

    private(set) var items: [ClosedPullRequest] = []
    private(set) var isLoading = false
    private(set) var hasFailed = false
    private(set) var hasNextPage = false
    private(set) var loadedAt: Date?

    var hasLoaded: Bool { loadedAt != nil }

    @ObservationIgnored private let fetchPage: FetchPage
    @ObservationIgnored private let onChange: ([ClosedPullRequest], Date) -> Void
    @ObservationIgnored private var endCursor: String?
    @ObservationIgnored private var generation = 0

    init(fetchPage: @escaping FetchPage, onChange: @escaping ([ClosedPullRequest], Date) -> Void = { _, _ in }) {
        self.fetchPage = fetchPage
        self.onChange = onChange
    }

    func loadIfNeeded(now: Date = .now) async {
        if let loadedAt, now.timeIntervalSince(loadedAt) < Self.staleAfter { return }
        await load(reloading: true, now: now)
    }

    func loadMore() async {
        guard hasNextPage else { return }
        await load(reloading: false)
    }

    func retry() async {
        await load(reloading: loadedAt == nil)
    }

    func clear() {
        generation += 1
        items = []
        isLoading = false
        hasFailed = false
        hasNextPage = false
        endCursor = nil
        loadedAt = nil
    }

    private func load(reloading: Bool, now: Date = .now) async {
        guard !isLoading else { return }
        let startedIn = generation
        isLoading = true
        hasFailed = false
        defer { if startedIn == generation { isLoading = false } }

        do {
            let page = try await fetchPage(reloading ? nil : endCursor)
            guard startedIn == generation else { return }
            items = reloading ? page.pullRequests : items + page.pullRequests
            endCursor = page.endCursor
            hasNextPage = page.hasNextPage
            if reloading { loadedAt = now }
            onChange(items, now)
        } catch {
            guard startedIn == generation else { return }
            hasFailed = true
            if reloading { loadedAt = nil }
        }
    }
}
