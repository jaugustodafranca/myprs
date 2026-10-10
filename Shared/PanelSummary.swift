import Foundation

/// Counts of what needs attention, shared by the menu bar panel and the widget.
struct PanelSummary {
    let open: Int
    let failing: Int
    let toAnswer: Int
    let ready: Int
    let mostUrgent: PullRequest?

    var needsAttention: Bool { failing > 0 || toAnswer > 0 }

    init(_ pullRequests: [PullRequest]) {
        open = pullRequests.count
        failing = pullRequests.filter { $0.checks == .failing }.count
        toAnswer = pullRequests.filter { $0.unansweredThreads > 0 }.count
        ready = pullRequests.filter(\.isReadyToMerge).count
        mostUrgent = pullRequests.sortedForDisplay().first
    }

    static func text(for pullRequests: [PullRequest]) -> String {
        guard !pullRequests.isEmpty else { return "No open pull requests" }
        let summary = PanelSummary(pullRequests)
        var parts = ["\(summary.open) open"]
        if summary.failing > 0 { parts.append("\(summary.failing) failing") }
        if summary.toAnswer > 0 { parts.append("\(summary.toAnswer) to answer") }
        return parts.joined(separator: " · ")
    }
}

extension PullRequest {
    var isReadyToMerge: Bool {
        review == .approved && checks == .passing && !hasConflicts
    }
}
