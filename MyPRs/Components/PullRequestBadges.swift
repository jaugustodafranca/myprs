import MyPRsKit
import SwiftUI

struct PullRequestBadges: View {
    let pullRequest: PullRequest

    init(pullRequest: PullRequest) {
        self.pullRequest = pullRequest
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            FlowLayout(spacing: 5) {
                checksBadge
                if let mergeState = pullRequest.mergeStateStatus {
                    Text(mergeState).font(.caption2).foregroundStyle(.secondary)
                }
                DiffBadge(additions: pullRequest.additions, deletions: pullRequest.deletions)
                FilesBadge(count: pullRequest.changedFiles)
                if pullRequest.unansweredThreads > 0 {
                    Badge(text: "\(pullRequest.unansweredThreads) to answer", symbol: "bubble.left.fill", color: .orange)
                }
                reviewBadge
                if pullRequest.hasConflicts {
                    Badge(text: "Conflicts", symbol: "exclamationmark.triangle.fill", color: .red)
                }
            }
            ForEach(Array((pullRequest.failedChecks ?? []).enumerated()), id: \.offset) { _, failure in
                Text(failure).font(.caption2).foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private var checksBadge: some View {
        let progress = "\(pullRequest.checksPassed)/\(pullRequest.checksTotal)"
        if pullRequest.checksTotal > 0 {
            switch pullRequest.checks {
            case .passing: Badge(text: progress, symbol: "checkmark", color: .green)
            case .failing: Badge(text: progress, symbol: "xmark", color: .red)
            case .running: Badge(text: "running \(progress)", symbol: "clock", color: .secondary)
            case .none: EmptyView()
            }
        }
    }

    @ViewBuilder
    private var reviewBadge: some View {
        switch pullRequest.review {
        case .approved: Badge(text: "Approved \(pullRequest.approvals)", symbol: "checkmark.seal.fill", color: .green)
        case .changesRequested: Badge(text: "Changes requested", color: .red)
        case .waiting: EmptyView()
        }
    }
}
