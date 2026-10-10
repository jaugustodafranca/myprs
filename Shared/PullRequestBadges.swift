import SwiftUI

struct Badge: View {
    let text: String
    var symbol: String?
    var color: Color = .secondary

    var body: some View {
        HStack(spacing: 3) {
            if let symbol { Image(systemName: symbol).imageScale(.small) }
            Text(text)
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.14), in: Capsule())
        .fixedSize()
    }
}

struct PullRequestBadges: View {
    let pullRequest: PullRequest

    var body: some View {
        FlowLayout(spacing: 5) {
            checksBadge
            diffBadge
            Badge(text: "\(pullRequest.changedFiles) file\(pullRequest.changedFiles == 1 ? "" : "s")")
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
    private var checksBadge: some View {
        let progress = "\(pullRequest.checksPassed)/\(pullRequest.checksTotal)"
        if pullRequest.checksTotal > 0 {
            switch pullRequest.checks {
            case .passing: Badge(text: progress, symbol: "checkmark", color: .green)
            case .failing: Badge(text: progress, symbol: "xmark", color: .red)
            case .running: Badge(text: "running", symbol: "clock", color: .secondary)
            case .none: EmptyView()
            }
        }
    }

    private var diffBadge: some View {
        HStack(spacing: 4) {
            Text("+\(CompactFormat.count(pullRequest.additions))").foregroundStyle(.green)
            Text("−\(CompactFormat.count(pullRequest.deletions))").foregroundStyle(.red)
        }
        .font(.caption2.weight(.medium).monospacedDigit())
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.secondary.opacity(0.14), in: Capsule())
        .fixedSize()
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
