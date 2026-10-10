import Foundation

/// The count shown next to the "Open" tab, tinted by the most urgent status.
struct OpenCountBadge {
    enum Tone { case failing, toAnswer, neutral }

    let count: Int
    let tone: Tone

    init?(_ summary: PanelSummary) {
        guard summary.open > 0 else { return nil }
        count = summary.open
        tone = Self.tone(for: summary)
    }

    private static func tone(for summary: PanelSummary) -> Tone {
        switch StatusPill(summary)?.tone {
        case .failing: .failing
        case .toAnswer: .toAnswer
        default: .neutral
        }
    }
}
