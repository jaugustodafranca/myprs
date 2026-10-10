import SwiftUI

struct PullRequestRowView: View {
    let pullRequest: PullRequest

    var body: some View {
        HStack(spacing: 8) {
            Link(destination: pullRequest.url) {
                HStack(spacing: 8) {
                    StatusDot(pullRequest: pullRequest)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(pullRequest.title)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 4)
                    reviewIcon
                    unansweredBadge
                }
            }
            Button(intent: CopyLinkIntent(url: pullRequest.url.absoluteString)) {
                Image(systemName: "link")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var subtitle: String {
        let reference = "\(pullRequest.repository)#\(pullRequest.number)"
        return pullRequest.isDraft ? "Draft · \(reference)" : reference
    }

    @ViewBuilder private var reviewIcon: some View {
        switch pullRequest.review {
        case .approved:
            Image(systemName: "checkmark.circle").foregroundStyle(.green).font(.caption)
        case .changesRequested:
            Image(systemName: "exclamationmark.bubble").foregroundStyle(.red).font(.caption)
        case .waiting:
            EmptyView()
        }
    }

    @ViewBuilder private var unansweredBadge: some View {
        if pullRequest.unansweredThreads > 0 {
            Label("\(pullRequest.unansweredThreads)", systemImage: "bubble.left")
                .font(.caption2)
                .foregroundStyle(.orange)
        }
    }
}
