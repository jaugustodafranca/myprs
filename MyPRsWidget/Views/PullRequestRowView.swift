import AppIntents
import MyPRsKit
import SwiftUI

struct PullRequestRowView: View {
    let pullRequest: PullRequest
    let detail: RowDetail
    var showsAuthor = false

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
                            if detail.showsBadges {
                                MetadataLine(pullRequest: pullRequest, asBadges: true)
                            } else {
                                referenceAndMetadataLine
                            }
                        } else {
                            referenceAndMetadataLine
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
            copyButton(systemImage: "link", intent: CopyLinkIntent(url: pullRequest.url.absoluteString))
            if detail.showsCopyBranch {
                copyButton(systemImage: "arrow.triangle.branch", intent: CopyBranchIntent(branch: pullRequest.headBranch))
            }
        }
    }

    private var reference: String { "\(pullRequest.repository)#\(pullRequest.number)" }

    private var referenceWithAuthor: some View {
        HStack(spacing: 4) {
            if showsAuthor, let login = pullRequest.authorLogin {
                AuthorInitialsView(login: login)
                Text(login)
                    .lineLimit(1)
                Text("\u{00B7}")
            }
            Text(reference)
                .lineLimit(1)
        }
        .font(.system(size: 10))
        .layoutPriority(1)
    }

    private var branchLine: some View {
        HStack(spacing: 6) {
            Text("\(pullRequest.headBranch) \u{2192} \(pullRequest.baseBranch)")
                .font(.system(size: 10, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
            if detail.showsBadges {
                Spacer(minLength: 0)
                referenceWithAuthor
            }
        }
        .foregroundStyle(.secondary)
    }

    private var referenceAndMetadataLine: some View {
        HStack(spacing: 8) {
            referenceWithAuthor
                .foregroundStyle(.secondary)
            MetadataLine(pullRequest: pullRequest, asBadges: false)
        }
    }

    private func copyButton(systemImage: String, intent: some AppIntent) -> some View {
        Button(intent: intent) {
            Image(systemName: systemImage)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
    }
}
