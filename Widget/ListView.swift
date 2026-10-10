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
            header
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

    private var header: some View {
        HStack {
            Text("MyPRs")
                .font(.system(size: 13, weight: .semibold))
                .widgetAccentable()
            Spacer()
            if showsScoreboard && isInlineScoreboard {
                ScoreboardView(summary: summary, isInline: true)
                Spacer()
            }
            Text("\(summary.open) open")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}
