import MyPRsKit
import SwiftUI
import WidgetKit

struct EntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PullRequestEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            if snapshot.pullRequests.isEmpty {
                emptyContent(updatedAt: snapshot.fetchedAt)
            } else {
                content(for: snapshot)
            }
        } else {
            emptyContent(updatedAt: nil)
        }
    }

    @ViewBuilder private func content(for snapshot: PullRequestSnapshot) -> some View {
        switch family {
        case .systemSmall:
            let summary = PanelSummary(snapshot.pullRequests)
            SmallView(summary: summary)
                .widgetURL(summary.mostUrgent?.url)
        case .systemLarge:
            ListView(snapshot: snapshot, rowLimit: 5, showsScoreboard: true, detail: .regular)
        case .systemExtraLarge:
            ListView(snapshot: snapshot, rowLimit: 6, showsScoreboard: true, detail: .full)
        default:
            ListView(snapshot: snapshot, rowLimit: 3, showsScoreboard: false, detail: .compact)
        }
    }

    @ViewBuilder private func emptyContent(updatedAt: Date?) -> some View {
        switch family {
        case .systemSmall:
            EmptySmallView(isSignedOut: updatedAt == nil)
        default:
            EmptyWidgetView(family: family, updatedAt: updatedAt)
        }
    }
}
