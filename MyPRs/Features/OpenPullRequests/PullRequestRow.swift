import MyPRsKit
import SwiftUI

struct PullRequestRow: View {
    let pullRequest: PullRequest
    var showsAuthor = false
    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            StatusDot(pullRequest: pullRequest)
                .padding(.top, 5)
                .fixedSize()
                .layoutPriority(2)
            VStack(alignment: .leading, spacing: 4) {
                Text(pullRequest.title)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.tail)
                BranchLine(head: pullRequest.headBranch, base: pullRequest.baseBranch)
                    .font(.caption.monospaced())
                metaLine
                PullRequestBadges(pullRequest: pullRequest)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipped()
            VStack(spacing: 2) {
                CopyButton(symbol: "arrow.triangle.branch", help: "Copy branch name", text: pullRequest.headBranch)
                CopyButton(symbol: "link", help: "Copy link", text: pullRequest.url.absoluteString)
            }
            .fixedSize()
            .layoutPriority(2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(isHovering ? Color.primary.opacity(0.07) : .clear)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onTapGesture(perform: open)
        .contextMenu { contextMenu }
    }

    private var metaLine: some View {
        PullRequestMetaLine(
            repository: pullRequest.repository,
            number: pullRequest.number,
            trailing: CompactFormat.age(from: pullRequest.createdAt),
            isDraft: pullRequest.isDraft,
            author: showsAuthor ? pullRequest.authorLogin.map { ($0, pullRequest.authorAvatarURL) } : nil
        )
    }

    @ViewBuilder
    private var contextMenu: some View {
        Button("Open on GitHub", action: open)
        Button("Copy link") { Pasteboard.copy(pullRequest.url.absoluteString) }
        Button("Copy branch name") { Pasteboard.copy(pullRequest.headBranch) }
        Button("Copy git checkout command") { Pasteboard.copy("git checkout \(pullRequest.headBranch)") }
    }

    private func open() {
        guard GitHubURL.isTrusted(pullRequest.url) else { return }
        NSWorkspace.shared.open(pullRequest.url)
    }
}
