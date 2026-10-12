import Foundation

/// The count shown next to the "Open" tab, tinted by the most urgent status.
public struct OpenCountBadge {
    public enum Tone { case failing, toAnswer, neutral }

    public let count: Int
    public let tone: Tone

    public var accessibilityLabel: String {
        "Open, \(count) \(count == 1 ? "pull request" : "pull requests")"
    }

    public init?(_ summary: PanelSummary) {
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
