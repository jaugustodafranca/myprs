import WidgetKit

struct PullRequestEntry: TimelineEntry {
    let date: Date
    let snapshot: PullRequestSnapshot?
}

struct Provider: TimelineProvider {
    private let refreshInterval: TimeInterval = 15 * 60

    func placeholder(in context: Context) -> PullRequestEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping (PullRequestEntry) -> Void) {
        completion(context.isPreview ? .sample : currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PullRequestEntry>) -> Void) {
        let nextRefresh = Date().addingTimeInterval(refreshInterval)
        completion(Timeline(entries: [currentEntry()], policy: .after(nextRefresh)))
    }

    private func currentEntry() -> PullRequestEntry {
        PullRequestEntry(date: Date(), snapshot: SnapshotStore.shared.load())
    }
}
