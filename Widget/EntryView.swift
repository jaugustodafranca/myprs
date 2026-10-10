import SwiftUI
import WidgetKit

struct EntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PullRequestEntry

    private var maxRows: Int { family == .systemLarge ? 7 : 3 }

    var body: some View {
        if let snapshot = entry.snapshot {
            if snapshot.pullRequests.isEmpty {
                message("No open PRs 🎉")
            } else {
                list(of: snapshot)
            }
        } else {
            message("Sign in from the MyPRs menu bar app")
        }
    }

    private func list(of snapshot: PullRequestSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(snapshot.pullRequests.sortedForDisplay().prefix(maxRows)) { pullRequest in
                PullRequestRowView(pullRequest: pullRequest)
            }
            Spacer(minLength: 0)
            Text("Updated \(snapshot.fetchedAt.formatted(date: .omitted, time: .shortened))")
                .font(.caption2)
                .foregroundStyle(.secondary)
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
