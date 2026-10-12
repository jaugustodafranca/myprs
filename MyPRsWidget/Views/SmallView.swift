import MyPRsKit
import SwiftUI

struct SmallView: View {
    let summary: PanelSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            AppMark()
            Spacer(minLength: 2)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(summary.open)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("open")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            attention
        }
        .font(.system(size: 12, weight: .medium))
        .lineLimit(1)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    @ViewBuilder private var attention: some View {
        if summary.needsAttention {
            if summary.failing > 0 {
                Text("\u{2717} \(summary.failing) CI failing")
                    .foregroundStyle(.red)
            }
            if summary.toAnswer > 0 {
                Text("\(summary.toAnswer) to answer")
                    .foregroundStyle(.orange)
            }
        } else {
            Text("\u{2713} All good")
                .foregroundStyle(.green)
        }
    }
}
