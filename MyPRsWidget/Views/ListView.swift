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

    private var groups: [PullRequestGroup<PullRequest>] {
        PullRequestGrouping.groups(isSearch ? snapshot.pullRequests : snapshot.pullRequests.sortedForDisplay())
    }

    private var totalRows: Int { groups.reduce(0) { $0 + $1.items.count } }

    private func visibleGroups(_ rowCount: Int) -> [(group: PullRequestGroup<PullRequest>, visible: [PullRequest], omitted: Int)] {
        var remaining = rowCount
        return groups.compactMap { group in
            let visibleCount = min(remaining, group.items.count)
            guard visibleCount > 0 else { return nil }
            remaining -= visibleCount
            return (group, Array(group.items.prefix(visibleCount)), group.items.count - visibleCount)
        }
    }

    var body: some View {
        ViewThatFits(in: .vertical) {
            ForEach(Array((0...min(rowLimit, totalRows)).reversed()), id: \.self) { rowCount in
                VStack(alignment: .leading, spacing: 0) {
                    content(rowCount: rowCount)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    WidgetListFooter(omittedCount: totalRows - rowCount, updatedAt: snapshot.fetchedAt)
                        .padding(.top, 8)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func content(rowCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            WidgetHeaderView(
                title: source.title,
                pill: pill,
                inlineScoreboard: showsScoreboard && isInlineScoreboard ? summary : nil
            )
            if showsScoreboard && !isInlineScoreboard {
                ScoreboardView(summary: summary)
            }
            VStack(alignment: .leading, spacing: 6) {
                ForEach(visibleGroups(rowCount), id: \.group.id) { visibleGroup in
                    WidgetPullRequestGroup(group: visibleGroup.group, visibleItems: visibleGroup.visible, omittedCount: visibleGroup.omitted) { pullRequest, parentNumber in
                        PullRequestRowView(
                            pullRequest: pullRequest, detail: detail, showsAuthor: isSearch, parentNumber: parentNumber
                        )
                    }
                }
            }
        }
    }
}
