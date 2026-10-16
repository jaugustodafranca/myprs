import AppIntents
import MyPRsKit
import SwiftUI

struct PullRequestRowView: View {
    let pullRequest: PullRequest
    let detail: RowDetail
    var showsAuthor = false
    var parentNumber: Int? = nil

    var body: some View {
        HStack(spacing: 8) {
            Link(destination: pullRequest.url) {
                HStack(alignment: .top, spacing: 8) {
                    StatusDot(pullRequest: pullRequest)
                        .widgetAccentable()
                        .padding(.top, 3)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(pullRequest.title)
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                            .widgetAccentable()
                        if detail.showsBranch {
                            branchLine
                        }
                        referenceAndMetadataLine
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            VStack(spacing: 1) {
                copyButton(systemImage: "link", intent: CopyLinkIntent(url: pullRequest.url.absoluteString))
                copyButton(systemImage: "arrow.triangle.branch", intent: CopyBranchIntent(branch: pullRequest.headBranch))
                copyButton(systemImage: "sparkles", intent: CopyPromptIntent(valuesJSON: Self.encodedPromptValues(for: pullRequest) ?? ""))
            }
        }
    }

    private var referenceWithAuthor: some View {
        HStack(spacing: 4) {
            if showsAuthor, let login = pullRequest.authorLogin {
                AuthorInitialsView(login: login)
                Text(login)
                    .lineLimit(1)
                Text("\u{00B7}")
            }
            Text(RepositoryName.short(pullRequest.repository))
                .lineLimit(1)
                .truncationMode(.middle)
            Text(verbatim: "#\(pullRequest.number)")
                .lineLimit(1)
                .fixedSize()
                .layoutPriority(1)
        }
        .font(.system(size: 10))
    }

    private var branchLine: some View {
        BranchLine(head: pullRequest.headBranch, base: pullRequest.baseBranch)
            .font(.system(size: 10, design: .monospaced))
    }

    private var referenceAndMetadataLine: some View {
        HStack(spacing: 8) {
            referenceWithAuthor
                .foregroundStyle(.secondary)
            if let parentNumber {
                Text("Base #\(parentNumber)")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .fixedSize()
            }
            MetadataLine(pullRequest: pullRequest, asBadges: detail.showsBranch && detail.showsBadges)
        }
    }

    private func copyButton(systemImage: String, intent: some AppIntent) -> some View {
        Button(intent: intent) {
            Image(systemName: systemImage)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 18, height: 16)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(systemImage == "link" ? "Copy pull request link" : (systemImage == "sparkles" ? "Copy AI review prompt" : "Copy branch name"))
        .accessibilityHint("Copies to the clipboard")
        .help(systemImage == "link" ? "Copy pull request link" : (systemImage == "sparkles" ? "Copy AI review prompt" : "Copy branch name"))
    }

    private static func encodedPromptValues(for pullRequest: PullRequest) -> String? {
        guard let data = try? JSONEncoder().encode(ReviewPromptValues.of(pullRequest)) else { return nil }
        return data.base64EncodedString()
    }
}
