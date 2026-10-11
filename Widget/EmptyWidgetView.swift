import SwiftUI
import WidgetKit

/// Widget content when there is nothing to list: no open PRs, or signed out
/// (when there is no snapshot, so no update time).
struct EmptyWidgetView: View {
    let family: WidgetFamily
    let updatedAt: Date?

    private var isMedium: Bool { family == .systemMedium }

    private var message: EmptyStateView {
        let axis: Axis = isMedium ? .horizontal : .vertical
        let symbolSize: CGFloat = isMedium ? 32 : 44
        return updatedAt == nil
            ? .signedOut(axis: axis, symbolSize: symbolSize)
            : .allCaughtUp(axis: axis, symbolSize: symbolSize)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WidgetHeaderView(summary: PanelSummary([]))
            message
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if let updatedAt {
                Text("Updated \(updatedAt.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
