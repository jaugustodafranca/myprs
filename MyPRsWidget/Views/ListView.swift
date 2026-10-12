import MyPRsKit
import SwiftUI

struct ListView: View {
    let snapshot: PullRequestSnapshot
    let rowLimit: Int
    let showsScoreboard: Bool
    let detail: RowDetail

    private var isInlineScoreboard: Bool { detail == .full }
    private var summary: PanelSummary { PanelSummary(snapshot.pullRequests) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WidgetHeaderView(summary: summary, showsInlineScoreboard: showsScoreboard && isInlineScoreboard)
            if showsScoreboard && !isInlineScoreboard {
                ScoreboardView(summary: summary)
            }
            VStack(alignment: .leading, spacing: 7) {
                ForEach(snapshot.pullRequests.sortedForDisplay().prefix(rowLimit)) { pullRequest in
                    PullRequestRowView(pullRequest: pullRequest, detail: detail)
                }
            }
            Spacer(minLength: 0)
            Text("Updated \(snapshot.fetchedAt.formatted(date: .omitted, time: .shortened))")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
        }
    }
}
