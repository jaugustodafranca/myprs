import SwiftUI
import WidgetKit

struct EntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PullRequestEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            if snapshot.pullRequests.isEmpty {
                message("No open PRs 🎉")
            } else {
                content(for: snapshot)
            }
        } else {
            message("Sign in from the MyPRs menu bar app")
        }
    }

    @ViewBuilder private func content(for snapshot: PullRequestSnapshot) -> some View {
        switch family {
        case .systemSmall:
            let summary = PullRequestSummary(snapshot.pullRequests)
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

    private func message(_ text: String) -> some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
