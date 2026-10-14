import MyPRsKit
import SwiftUI

struct EmptySmallView: View {
    let source: WidgetSource
    let isSignedOut: Bool

    private var isSearch: Bool { source != .mine }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            AppMark()
            Spacer(minLength: 2)
            if isSignedOut {
                EmptyStateView.signedOut(symbolSize: 28)
                    .frame(maxWidth: .infinity)
            } else {
                zeroCount
                Text(isSearch ? "\u{2713} Nothing to review" : "\u{2713} All caught up")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.green)
            }
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var zeroCount: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("0")
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text(isSearch ? "to review" : "open")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
}
