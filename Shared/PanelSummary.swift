import Foundation

enum PanelSummary {
    static func text(for pullRequests: [PullRequest]) -> String {
        guard !pullRequests.isEmpty else { return "No open pull requests" }
        var parts = ["\(pullRequests.count) open"]
        let failing = pullRequests.filter { $0.checks == .failing }.count
        let toAnswer = pullRequests.filter { $0.unansweredThreads > 0 }.count
        if failing > 0 { parts.append("\(failing) failing") }
        if toAnswer > 0 { parts.append("\(toAnswer) to answer") }
        return parts.joined(separator: " · ")
    }
}
