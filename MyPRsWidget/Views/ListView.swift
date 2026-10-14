import MyPRsKit
import SwiftUI

struct ListView: View {
    let source: WidgetSource
    let snapshot: PullRequestSnapshot
    let rowLimit: Int
    let showsScoreboard: Bool
    let detail: RowDetail

    private var isInlineScoreboard: Bool { detail == .full }
    private var summary: PanelSummary { PanelSummary(snapshot.pullRequests) }
    private var isSearch: Bool { source != .mine }

    private var pill: StatusPill? {
        isSearch ? StatusPill(toReview: snapshot.pullRequests.count) : StatusPill(summary)
    }

    /// A search keeps GitHub's order, which may come from a `sort:` qualifier.
    private var rows: [PullRequest] {
        isSearch ? snapshot.pullRequests : snapshot.pullRequests.sortedForDisplay()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WidgetHeaderView(
                title: source.title,
                pill: pill,
                inlineScoreboard: showsScoreboard && isInlineScoreboard ? summary : nil
            )
            if showsScoreboard && !isInlineScoreboard {
                ScoreboardView(summary: summary)
            }
            VStack(alignment: .leading, spacing: 7) {
                ForEach(rows.prefix(rowLimit)) { pullRequest in
                    PullRequestRowView(pullRequest: pullRequest, detail: detail, showsAuthor: isSearch)
                }
            }
            Spacer(minLength: 0)
            Text("Updated \(snapshot.fetchedAt.formatted(date: .omitted, time: .shortened))")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
        }
    }
}
