import MyPRsKit
import WidgetKit

struct PullRequestEntry: TimelineEntry {
    let date: Date
    let source: WidgetSource
    let snapshot: PullRequestSnapshot?
}

struct Provider: AppIntentTimelineProvider {
    private let refreshInterval: TimeInterval = 15 * 60

    func placeholder(in context: Context) -> PullRequestEntry { .sample }

    func snapshot(for configuration: SelectSourceIntent, in context: Context) async -> PullRequestEntry {
        context.isPreview ? .sample : entry(for: configuration)
    }

    func timeline(for configuration: SelectSourceIntent, in context: Context) async -> Timeline<PullRequestEntry> {
        Timeline(entries: [entry(for: configuration)], policy: .after(Date().addingTimeInterval(refreshInterval)))
    }

    private func entry(for configuration: SelectSourceIntent) -> PullRequestEntry {
        let source = WidgetSource.resolve(id: configuration.source?.id, in: SavedSearchStore.shared.loadSearches())
        return PullRequestEntry(date: Date(), source: source, snapshot: loadSnapshot(for: source).map(withTrustedLinksOnly))
    }

    private func loadSnapshot(for source: WidgetSource) -> PullRequestSnapshot? {
        switch source {
        case .mine:
            return SnapshotStore.shared.load()
        case .search(let search):
            guard let saved = SavedSearchStore.shared.loadSnapshot(for: search.id) else { return nil }
            return PullRequestSnapshot(login: "", pullRequests: saved.pullRequests, fetchedAt: saved.fetchedAt)
        }
    }

    private func withTrustedLinksOnly(_ snapshot: PullRequestSnapshot) -> PullRequestSnapshot {
        PullRequestSnapshot(
            login: snapshot.login,
            pullRequests: snapshot.pullRequests.filter { GitHubURL.isTrusted($0.url) },
            fetchedAt: snapshot.fetchedAt
        )
    }
}
