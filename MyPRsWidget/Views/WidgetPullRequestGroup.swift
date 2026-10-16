import MyPRsKit
import SwiftUI

struct WidgetPullRequestGroup<Item: GroupablePullRequest, RowContent: View>: View {
    let group: PullRequestGroup<Item>
    let visibleItems: [Item]
    let omittedCount: Int
    let row: (Item, Int?) -> RowContent

    init(
        group: PullRequestGroup<Item>,
        visibleItems: [Item],
        omittedCount: Int,
        @ViewBuilder row: @escaping (Item, Int?) -> RowContent
    ) {
        self.group = group
        self.visibleItems = visibleItems
        self.omittedCount = omittedCount
        self.row = row
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if group.isRelated {
                HStack(spacing: 5) {
                    Text("\(RepositoryName.short(group.repository)) · \(group.baseBranch)")
                        .lineLimit(1).truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(omittedCount > 0
                         ? "\(group.items.count) PRs · \(omittedCount) hidden"
                         : "\(group.items.count) PRs")
                        .fixedSize()
                }
                .font(.system(size: 9, weight: .medium))
                ForEach(visibleItems) { item in row(item, group.parentNumbers[item.id]) }
            } else {
                ForEach(visibleItems) { item in row(item, nil) }
            }
        }
        .padding(group.isRelated ? 6 : 0)
        .overlay {
            if group.isRelated {
                RoundedRectangle(cornerRadius: 7).stroke(.secondary.opacity(0.35), lineWidth: 0.7)
            }
        }
        .accessibilityElement(children: .contain)
    }
}
