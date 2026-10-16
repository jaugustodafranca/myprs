import MyPRsKit
import SwiftUI

struct ClosedPullRequestRow: View {
    let pullRequest: ClosedPullRequest
    var parentNumber: Int? = nil
    @State private var isHovering = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(pullRequest.title)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.tail)
                BranchLine(head: pullRequest.headBranch, base: pullRequest.baseBranch)
                    .font(.caption.monospaced())
                if let parentNumber {
                    Text("Base: #\(parentNumber)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                PullRequestMetaLine(repository: pullRequest.repository, number: pullRequest.number, trailing: endedText)
                badges
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipped()
            VStack(spacing: 2) {
                CopyButton(symbol: "arrow.triangle.branch", help: "Copy branch name", text: pullRequest.headBranch)
                CopyButton(symbol: "link", help: "Copy link", text: pullRequest.url.absoluteString)
                CopyButton(symbol: "sparkles", help: "Copy AI review prompt", text: reviewPrompt)
            }
            .fixedSize()
            .layoutPriority(2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isHovering ? Color.primary.opacity(0.035) : .clear)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
        }
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

    private var endedText: String {
        let verb = pullRequest.state == .merged ? "merged" : "closed"
        let age = CompactFormat.age(from: pullRequest.endedAt)
        let when = age == "now" ? "just now" : "\(age) ago"
        return "\(verb) \(when)"
    }

    @ViewBuilder
    private var contextMenu: some View {
        Button("Open on GitHub", action: open)
        Button("Copy link") { Pasteboard.copy(pullRequest.url.absoluteString) }
        Button("Copy branch name") { Pasteboard.copy(pullRequest.headBranch) }
        Button("Copy AI Review Prompt") { Pasteboard.copy(reviewPrompt) }
        Button("Copy git checkout command") { Pasteboard.copy("git checkout \(pullRequest.headBranch)") }
    }

    private var reviewPrompt: String {
        ReviewPromptTemplate.render(ReviewPromptStore.standard.template, values: ReviewPromptValues.of(pullRequest))
    }

    private func open() {
        guard GitHubURL.isTrusted(pullRequest.url) else { return }
        NSWorkspace.shared.open(pullRequest.url)
    }
}
