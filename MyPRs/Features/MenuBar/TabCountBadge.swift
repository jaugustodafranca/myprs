import Foundation
import MyPRsKit

/// The count shown next to a tab name. The Open count is tinted by the most urgent status.
struct TabCountBadge {
    enum Tone { case failing, toAnswer, neutral }

    let tab: PanelTab
    let count: Int
    let tone: Tone

    var accessibilityLabel: String {
        "\(tab.rawValue), \(count) \(count == 1 ? "pull request" : "pull requests")"
    }

    init?(_ summary: PanelSummary) {
        guard summary.open > 0 else { return nil }
        tab = .open
        count = summary.open
        tone = Self.tone(for: summary)
    }

    init?(reviewCount: Int) {
        guard reviewCount > 0 else { return nil }
        tab = .review
        count = reviewCount
        tone = .neutral
    }

    private static func tone(for summary: PanelSummary) -> Tone {
        switch StatusPill(summary)?.tone {
        case .failing: .failing
        case .toAnswer: .toAnswer
        default: .neutral
        }
    }
}
