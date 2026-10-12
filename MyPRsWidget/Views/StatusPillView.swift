import MyPRsKit
import SwiftUI

struct StatusPillView: View {
    let pill: StatusPill

    var body: some View {
        Text(pill.text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15), in: Capsule())
            .widgetAccentable(pill.tone != .neutral)
    }

    private var color: Color {
        switch pill.tone {
        case .failing: .red
        case .toAnswer: .orange
        case .clear: .green
        case .neutral: .secondary
        }
    }
}
