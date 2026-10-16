import AppIntents
import MyPRsKit
import SwiftUI

struct RecentPullRequestRowView: View {
    let pullRequest: ClosedPullRequest
    let parentNumber: Int?

    private var promptValues: String? {
        guard let data = try? JSONEncoder().encode(ReviewPromptValues.of(pullRequest)) else { return nil }
        return data.base64EncodedString()
    }

    var body: some View {
        HStack(spacing: 5) {
            Link(destination: pullRequest.url) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(pullRequest.title).font(.system(size: 11, weight: .semibold)).lineLimit(1)
                    BranchLine(head: pullRequest.headBranch, base: pullRequest.baseBranch)
                        .font(.system(size: 9, design: .monospaced))
                    HStack(spacing: 4) {
                        Text(RepositoryName.short(pullRequest.repository))
                            .truncationMode(.middle)
                        Text("#\(pullRequest.number)").fixedSize()
                        Text(pullRequest.state == .merged ? "Merged" : "Closed")
                            .foregroundStyle(pullRequest.state == .merged ? .purple : .secondary)
                            .fixedSize()
                        if let parentNumber { Text("· Base #\(parentNumber)").fixedSize() }
                    }
                    .font(.system(size: 9)).foregroundStyle(.secondary).lineLimit(1)
                    HStack(spacing: 4) {
                        Text("+\(CompactFormat.count(pullRequest.additions))")
                            .foregroundStyle(.green)
                        Text("−\(CompactFormat.count(pullRequest.deletions))")
                            .foregroundStyle(.red)
                        Text("\(pullRequest.changedFiles) file\(pullRequest.changedFiles == 1 ? "" : "s")")
                        Spacer(minLength: 0)
                        Text(endedAge)
                    }
                    .font(.system(size: 9)).foregroundStyle(.secondary).lineLimit(1)

                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            VStack(spacing: 1) {
                action("link", label: "Copy pull request link", intent: CopyLinkIntent(url: pullRequest.url.absoluteString))
                action("arrow.triangle.branch", label: "Copy branch name", intent: CopyBranchIntent(branch: pullRequest.headBranch))
                action("sparkles", label: "Copy AI review prompt", intent: CopyPromptIntent(valuesJSON: promptValues ?? ""))
            }
        }
    }

    private var endedAge: String {
        let age = CompactFormat.age(from: pullRequest.endedAt)
        return age == "now" ? age : "\(age) ago"
    }

    private func action(_ symbol: String, label: String, intent: some AppIntent) -> some View {
        Button(intent: intent) {
            Image(systemName: symbol).font(.system(size: 10)).foregroundStyle(.secondary).frame(width: 18, height: 16)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityHint("Copies to the clipboard")
        .help(label)
    }
}
