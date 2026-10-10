import Foundation

struct PullRequestSummary {
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
}

extension PullRequest {
    var isReadyToMerge: Bool {
        review == .approved && checks == .passing && !hasConflicts
    }
}
