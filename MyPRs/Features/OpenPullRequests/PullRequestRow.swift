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
            VStack(alignment: .leading, spacing: 4) {
                Text(pullRequest.title)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.tail)
                BranchLine(head: pullRequest.headBranch, base: pullRequest.baseBranch)
                detailsLine
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                PullRequestBadges(pullRequest: pullRequest)
            }
            Spacer(minLength: 0)
            VStack(spacing: 2) {
                CopyButton(symbol: "arrow.triangle.branch", help: "Copy branch name", text: pullRequest.headBranch)
                CopyButton(symbol: "link", help: "Copy link", text: pullRequest.url.absoluteString)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(isHovering ? Color.primary.opacity(0.07) : .clear)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onTapGesture(perform: open)
        .contextMenu { contextMenu }
    }

    @ViewBuilder
    private var detailsLine: some View {
        if showsAuthor, let login = pullRequest.authorLogin {
            HStack(spacing: 4) {
                AuthorLabel(login: login, avatarURL: pullRequest.authorAvatarURL)
                    .fixedSize()
                Text("· \(details)")
            }
        } else {
            Text(details)
        }
    }

    private var details: String {
        let age = CompactFormat.age(from: pullRequest.createdAt)
        let text = "\(pullRequest.repository)#\(pullRequest.number) · \(age)"
        return pullRequest.isDraft ? "Draft · \(text)" : text
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
