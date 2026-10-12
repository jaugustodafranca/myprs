import MyPRsKit
import SwiftUI

struct MetadataLine: View {
    let pullRequest: PullRequest
    let asBadges: Bool

    private var items: [MetadataItem] { MetadataItem.items(for: pullRequest) }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            ForEach(0..<4, id: \.self) { tightness in
                line(items.filter { !$0.isDroppable(whenSpaceIsTight: tightness) })
            }
        }
    }

    private func line(_ items: [MetadataItem]) -> some View {
        HStack(spacing: asBadges ? 4 : 8) {
            ForEach(items) { item in
                if asBadges {
                    item.content
                        .foregroundStyle(item.color)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(item.color.opacity(0.15), in: Capsule())
                } else {
                    item.content.foregroundStyle(item.color)
                }
            }
        }
        .font(.system(size: 10, weight: .medium))
        .lineLimit(1)
        .fixedSize()
    }
}
