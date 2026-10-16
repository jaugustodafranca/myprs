import MyPRsKit
import SwiftUI

struct GroupedPullRequestList<Item: GroupablePullRequest, Row: View>: View {
    let groups: [PullRequestGroup<Item>]
    let row: (Item, Int?) -> Row
    var summary: (([Item]) -> String?)? = nil
    let onCollapseChanged: ((Bool) -> Void)?

    @State private var collapsedGroupIDs: Set<String> = []

    init(
        groups: [PullRequestGroup<Item>],
        summary: (([Item]) -> String?)? = nil,
        onCollapseChanged: ((Bool) -> Void)? = nil,
        @ViewBuilder row: @escaping (Item, Int?) -> Row
    ) {
        self.groups = groups
        self.summary = summary
        self.onCollapseChanged = onCollapseChanged
        self.row = row
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                if group.isRelated {
                    relatedGroup(group)
                } else if let item = group.items.first {
                    row(item, nil)
                }

                if index != groups.count - 1 {
                    Divider().padding(.leading, 32)
                }
            }
        }
        .onAppear {
            onCollapseChanged?(!collapsedGroupIDs.isEmpty)
        }
        .onChange(of: groups.filter(\.isRelated).map(\.id)) { _, ids in
            collapsedGroupIDs.formIntersection(ids)
            onCollapseChanged?(!collapsedGroupIDs.isEmpty)
        }
    }

    private func relatedGroup(_ group: PullRequestGroup<Item>) -> some View {
        VStack(spacing: 0) {
            Button { toggle(group.id) } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.caption)
                    Text("\(group.repository) · \(group.baseBranch)")
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .layoutPriority(1)
                    Spacer(minLength: 4)
                    if let summaryText = summary?(group.items) {
                        Text(summaryText)
                            .lineLimit(1)
                            .fixedSize()
                            .foregroundStyle(.secondary)
                    }
                    Text("\(group.items.count) related PRs")
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .fixedSize()
                    Image(systemName: collapsedGroupIDs.contains(group.id) ? "chevron.right" : "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 10)

            if !collapsedGroupIDs.contains(group.id) {
                VStack(spacing: 0) {
                    ForEach(Array(group.items.enumerated()), id: \.element.id) { index, item in
                        row(item, group.parentNumbers[item.id])
                        if index != group.items.count - 1 {
                            Divider().padding(.leading, 32)
                        }
                    }
                }
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 9)
                .fill(Color.primary.opacity(0.025))
                .overlay {
                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(Color.primary.opacity(0.13), lineWidth: 1)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private func toggle(_ id: String) {
        if collapsedGroupIDs.contains(id) {
            collapsedGroupIDs.remove(id)
        } else {
            collapsedGroupIDs.insert(id)
        }
        onCollapseChanged?(!collapsedGroupIDs.isEmpty)
    }
}
