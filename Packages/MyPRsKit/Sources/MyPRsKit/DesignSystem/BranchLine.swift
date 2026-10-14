import SwiftUI

/// "head → base" in the caller's font. Both names truncate in the middle; the head keeps the larger share.
public struct BranchLine: View {
    let head: String
    let base: String

    public init(head: String, base: String) {
        self.head = head
        self.base = base
    }

    public var body: some View {
        BranchLineLayout(spacing: 4) {
            Text(head).lineLimit(1).truncationMode(.middle)
            Text("→")
            Text(base).lineLimit(1).truncationMode(.middle)
        }
        .foregroundStyle(.secondary)
        .help("\(head) → \(base)")
    }
}

private struct BranchLineLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let widths = columnWidths(proposal: proposal, subviews: subviews)
        let height = subviews.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
        return CGSize(width: widths.reduce(0, +) + spacing * 2, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let widths = columnWidths(proposal: ProposedViewSize(width: bounds.width, height: nil), subviews: subviews)
        var x = bounds.minX
        for (subview, width) in zip(subviews, widths) {
            subview.place(at: CGPoint(x: x, y: bounds.minY), anchor: .topLeading, proposal: ProposedViewSize(width: width, height: bounds.height))
            x += width + spacing
        }
    }

    private func columnWidths(proposal: ProposedViewSize, subviews: Subviews) -> [CGFloat] {
        let ideal = subviews.map { $0.sizeThatFits(.unspecified).width }
        guard let proposed = proposal.width else { return ideal }
        let available = proposed - ideal[1] - spacing * 2
        let split = BranchWidthAllocation(headIdeal: ideal[0], baseIdeal: ideal[2], available: available)
        return [split.head, ideal[1], split.base]
    }
}
