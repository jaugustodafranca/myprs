import MyPRsKit
import SwiftUI
import WidgetKit

/// Widget content when there is nothing to list: no open PRs, or signed out
/// (when there is no snapshot, so no update time).
struct EmptyWidgetView: View {
    let source: WidgetSource
    let family: WidgetFamily
    let updatedAt: Date?
    let isSignedOut: Bool

    private var isMedium: Bool { family == .systemMedium }

    private var message: EmptyStateView {
        let axis: Axis = isMedium ? .horizontal : .vertical
        let symbolSize: CGFloat = isMedium ? 32 : 44
        if isSignedOut {
            return .signedOut(axis: axis, symbolSize: symbolSize)
        }
        return source == .mine
            ? .allCaughtUp(axis: axis, symbolSize: symbolSize)
            : .nothingToReview(axis: axis, symbolSize: symbolSize)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WidgetHeaderView(title: source.title, pill: nil)
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
