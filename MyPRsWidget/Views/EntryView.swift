import MyPRsKit
import SwiftUI
import WidgetKit

struct EntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PullRequestEntry

    private var isSearch: Bool { entry.source != .mine }

    var body: some View {
        if let snapshot = entry.snapshot, !snapshot.pullRequests.isEmpty {
            content(for: snapshot)
        } else {
            emptyContent(updatedAt: entry.snapshot?.fetchedAt)
        }
    }

    @ViewBuilder private func content(for snapshot: PullRequestSnapshot) -> some View {
        switch family {
        case .systemSmall:
            smallContent(for: snapshot)
        case .systemLarge:
            ListView(source: entry.source, snapshot: snapshot, rowLimit: 5, showsScoreboard: !isSearch, detail: .regular)
        case .systemExtraLarge:
            ListView(source: entry.source, snapshot: snapshot, rowLimit: 6, showsScoreboard: !isSearch, detail: .full)
        default:
            ListView(source: entry.source, snapshot: snapshot, rowLimit: 3, showsScoreboard: false, detail: .compact)
        }
    }

    @ViewBuilder private func smallContent(for snapshot: PullRequestSnapshot) -> some View {
        if isSearch {
            ReviewSmallView(title: entry.source.title, count: snapshot.pullRequests.count)
                .widgetURL(snapshot.pullRequests.first?.url)
        } else {
            let summary = PanelSummary(snapshot.pullRequests)
            SmallView(summary: summary)
                .widgetURL(summary.mostUrgent?.url)
        }
    }

    @ViewBuilder private func emptyContent(updatedAt: Date?) -> some View {
        switch family {
        case .systemSmall:
            EmptySmallView(source: entry.source, isSignedOut: !isSearch && updatedAt == nil)
        default:
            EmptyWidgetView(source: entry.source, family: family, updatedAt: updatedAt)
        }
    }
}
