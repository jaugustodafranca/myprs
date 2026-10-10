import SwiftUI

struct SmallView: View {
    let summary: PanelSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("MyPRs")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .widgetAccentable()
            Text("\(summary.open) open")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Spacer(minLength: 4)
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
        .font(.system(size: 12, weight: .medium))
        .lineLimit(1)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
