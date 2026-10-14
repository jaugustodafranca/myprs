import MyPRsKit
import SwiftUI

struct WidgetHeaderView: View {
    let title: String
    let pill: StatusPill?
    var inlineScoreboard: PanelSummary?

    var body: some View {
        HStack(spacing: 6) {
            AppMark()
            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            Spacer(minLength: 4)
            if let inlineScoreboard {
                ScoreboardView(summary: inlineScoreboard, isInline: true)
                Spacer(minLength: 4)
            }
            if let pill {
                StatusPillView(pill: pill)
            }
        }
    }
}
