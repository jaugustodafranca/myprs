import MyPRsKit
import SwiftUI

struct RecentListView: View {
    let snapshot: ClosedPullRequestSnapshot
    let rowLimit: Int

    private var groups: [PullRequestGroup<ClosedPullRequest>] { PullRequestGrouping.groups(snapshot.pullRequests) }
    private var totalRows: Int { groups.reduce(0) { $0 + $1.items.count } }

    private func visibleGroups(_ rowCount: Int) -> [(group: PullRequestGroup<ClosedPullRequest>, visible: [ClosedPullRequest], omitted: Int)] {
        var remaining = rowCount
        return groups.compactMap { group in
            let count = min(remaining, group.items.count)
            guard count > 0 else { return nil }
            remaining -= count
            return (group, Array(group.items.prefix(count)), group.items.count - count)
        }
    }

    var body: some View {
        ViewThatFits(in: .vertical) {
            ForEach(Array((0...min(rowLimit, totalRows)).reversed()), id: \.self) { rowCount in
                VStack(alignment: .leading, spacing: 7) {
                    WidgetHeaderView(title: WidgetSource.recentTitle, pill: nil)
                    ForEach(visibleGroups(rowCount), id: \.group.id) { part in
                        WidgetPullRequestGroup(group: part.group, visibleItems: part.visible, omittedCount: part.omitted) { pullRequest, parentNumber in
                            RecentPullRequestRowView(pullRequest: pullRequest, parentNumber: parentNumber)
                        }
                    }
                    WidgetListFooter(omittedCount: totalRows - rowCount, updatedAt: snapshot.fetchedAt)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
