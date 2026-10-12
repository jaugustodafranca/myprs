import Foundation

/// Counts of what needs attention, shared by the menu bar panel and the widget.
public struct PanelSummary {
    public let open: Int
    public let failing: Int
    public let toAnswer: Int
    public let ready: Int
    public let mostUrgent: PullRequest?

    public var needsAttention: Bool { failing > 0 || toAnswer > 0 }

    public init(_ pullRequests: [PullRequest]) {
        open = pullRequests.count
        failing = pullRequests.filter { $0.checks == .failing }.count
        toAnswer = pullRequests.filter { $0.unansweredThreads > 0 }.count
        ready = pullRequests.filter(\.isReadyToMerge).count
        mostUrgent = pullRequests.sortedForDisplay().first
    }

    public static func text(for pullRequests: [PullRequest]) -> String {
        guard !pullRequests.isEmpty else { return "No open pull requests" }
        let summary = PanelSummary(pullRequests)
        var parts = ["\(summary.open) open"]
        if summary.failing > 0 { parts.append("\(summary.failing) failing") }
        if summary.toAnswer > 0 { parts.append("\(summary.toAnswer) to answer") }
        return parts.joined(separator: " · ")
    }
}

extension PanelSummary {
    public init(open: Int, failing: Int, toAnswer: Int, ready: Int) {
        self.open = open
        self.failing = failing
        self.toAnswer = toAnswer
        self.ready = ready
        mostUrgent = nil
    }
}

extension PullRequest {
    var isReadyToMerge: Bool {
        review == .approved && checks == .passing && !hasConflicts
    }
}
