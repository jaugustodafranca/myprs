import MyPRsKit
import SwiftUI
import WidgetKit

struct EntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PullRequestEntry

    private var isSearch: Bool { entry.source != .mine && entry.source != .recent }

    var body: some View {
        if entry.isSignedOut {
            emptyContent(updatedAt: nil)
        } else if entry.source == .recent, let recent = entry.recentSnapshot {
            if recent.pullRequests.isEmpty {
                emptyContent(updatedAt: recent.fetchedAt, message: "No recent pull requests")
            } else {
                recentContent(recent)
            }
        } else if entry.source == .recent {
            emptyContent(updatedAt: nil, message: "Refresh to show Recent")
        } else if let snapshot = entry.snapshot, !snapshot.pullRequests.isEmpty {
            content(for: snapshot)
        } else {
            emptyContent(updatedAt: entry.snapshot?.fetchedAt, message: entry.snapshot == nil && !entry.isSignedOut ? "Waiting for the app to refresh" : nil)
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

    @ViewBuilder private func recentContent(_ snapshot: ClosedPullRequestSnapshot) -> some View {
        switch family {
        case .systemSmall:
            ReviewSmallView(title: entry.source.title, count: snapshot.pullRequests.count, label: "recent")
                .widgetURL(snapshot.pullRequests.first?.url)
        case .systemLarge:
            RecentListView(snapshot: snapshot, rowLimit: 5)
        case .systemExtraLarge:
            RecentListView(snapshot: snapshot, rowLimit: 6)
        default:
            RecentListView(snapshot: snapshot, rowLimit: 3)
        }
    }

    @ViewBuilder private func emptyContent(updatedAt: Date?, message: String? = nil) -> some View {
        switch family {
        case .systemSmall:
            EmptySmallView(source: entry.source, isSignedOut: entry.isSignedOut, message: message)
        default:
            EmptyWidgetView(source: entry.source, family: family, updatedAt: updatedAt, isSignedOut: entry.isSignedOut, message: message)
        }
    }
}
