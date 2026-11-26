import MyPRsKit
import SwiftUI

struct PullRequestBadges: View {
    let pullRequest: PullRequest
    @State private var showsFailedChecks = false

    init(pullRequest: PullRequest) {
        self.pullRequest = pullRequest
    }

    var body: some View {
        FlowLayout(spacing: 5) {
            checksAndMergeState
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
    }

    @ViewBuilder
    private var checksAndMergeState: some View {
        if let state = pullRequest.mergeStateStatus, state != "CLEAN" {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                checksBadge
                Text(state == "BLOCKED" ? "Merge blocked" : state.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .help("GitHub reports the merge state as \(state)")
            }
        } else {
            checksBadge
        }
    }

    @ViewBuilder
    private var checksBadge: some View {
        let progress = "\(pullRequest.checksPassed)/\(pullRequest.checksTotal)"
        if pullRequest.checksTotal > 0 {
            Group {
                switch pullRequest.checks {
                case .passing: Badge(text: progress, symbol: "checkmark", color: .green)
                case .failing: failingBadge(progress)
                case .running: Badge(text: "running \(progress)", symbol: "clock", color: .secondary)
                case .none: EmptyView()
                }
            }
            .help(checksHelp)
        }
    }

    private var checksHelp: String {
        let hasDetails = pullRequest.checks == .failing && pullRequest.failedChecks?.isEmpty == false
        let hint = hasDetails ? "Show failed checks" : "\(pullRequest.checksPassed) of \(pullRequest.checksTotal) checks passed"
        guard let state = pullRequest.mergeStateStatus else { return hint }
        return "\(hint)\nGitHub merge state · \(state)"
    }

    @ViewBuilder
    private func failingBadge(_ progress: String) -> some View {
        if let failures = pullRequest.failedChecks, !failures.isEmpty {
            Button { showsFailedChecks = true } label: {
                Badge(text: progress, symbol: "xmark", color: .red, showsDisclosure: true)
                    .frame(minHeight: 22, alignment: .top)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Show failed checks")
            .accessibilityValue("\(pullRequest.checksPassed) of \(pullRequest.checksTotal) checks passed, \(failures.count) failed")
            .popover(isPresented: $showsFailedChecks) {
                FailedChecksView(failures: failures)
            }
        } else {
            Badge(text: progress, symbol: "xmark", color: .red)
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
