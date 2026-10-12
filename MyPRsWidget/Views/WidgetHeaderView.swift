import MyPRsKit
import SwiftUI

struct WidgetHeaderView: View {
    let summary: PanelSummary
    var showsInlineScoreboard = false

    var body: some View {
        HStack(spacing: 6) {
            AppMark()
            Text("Pull requests")
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            Spacer(minLength: 4)
            if showsInlineScoreboard {
                ScoreboardView(summary: summary, isInline: true)
                Spacer(minLength: 4)
            }
            if let pill = StatusPill(summary) {
                StatusPillView(pill: pill)
            }
        }
    }
}
