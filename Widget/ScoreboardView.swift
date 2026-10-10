import SwiftUI

struct ScoreboardView: View {
    let summary: PanelSummary
    var isInline = false

    var body: some View {
        HStack(spacing: 6) {
            tile(summary.failing, "CI failing", .red)
            tile(summary.toAnswer, "To answer", .orange)
            tile(summary.ready, "Ready", .green)
        }
    }

    private func tile(_ count: Int, _ label: String, _ color: Color) -> some View {
        let layout = isInline ? AnyLayout(HStackLayout(spacing: 4)) : AnyLayout(VStackLayout(spacing: 0))
        return layout {
            Text("\(count)")
                .font(.system(size: isInline ? 13 : 18, weight: .bold, design: .rounded))
                .foregroundStyle(count > 0 ? color : .secondary)
                .widgetAccentable(count > 0)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: isInline ? nil : .infinity)
        .padding(.vertical, isInline ? 2 : 4)
        .padding(.horizontal, isInline ? 8 : 0)
        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}
