import Foundation

/// The single most important status of the pull requests, shown as a pill in the widget header.
struct StatusPill {
    enum Tone { case failing, toAnswer, clear, neutral }

    let text: String
    let tone: Tone

    init?(_ summary: PanelSummary) {
        guard summary.open > 0 else { return nil }
        if summary.failing > 0 {
            self.init(text: "\(summary.failing) failing", tone: .failing)
        } else if summary.toAnswer > 0 {
            self.init(text: "\(summary.toAnswer) to answer", tone: .toAnswer)
        } else if summary.ready > 0 {
            self.init(text: "All clear", tone: .clear)
        } else {
            self.init(text: "\(summary.open) open", tone: .neutral)
        }
    }

    private init(text: String, tone: Tone) {
        self.text = text
        self.tone = tone
    }
}
