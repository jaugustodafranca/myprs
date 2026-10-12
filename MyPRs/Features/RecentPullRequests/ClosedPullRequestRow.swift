import MyPRsKit
import SwiftUI

struct ClosedPullRequestRow: View {
    let pullRequest: ClosedPullRequest
    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(pullRequest.title)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.tail)
                BranchLine(head: pullRequest.headBranch, base: pullRequest.baseBranch)
                Text(details)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                badges
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

    private var badges: some View {
        FlowLayout(spacing: 5) {
            switch pullRequest.state {
            case .merged: Badge(text: "Merged", symbol: "arrow.triangle.merge", color: .purple)
            case .closed: Badge(text: "Closed", symbol: "xmark.circle", color: .gray)
            }
            DiffBadge(additions: pullRequest.additions, deletions: pullRequest.deletions)
            FilesBadge(count: pullRequest.changedFiles)
        }
    }

    private var details: String {
        let verb = pullRequest.state == .merged ? "merged" : "closed"
        let age = CompactFormat.age(from: pullRequest.endedAt)
        let when = age == "now" ? "just now" : "\(age) ago"
        return "\(pullRequest.repository)#\(pullRequest.number) · \(verb) \(when)"
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
