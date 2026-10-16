import MyPRsKit
import SwiftUI

struct PullRequestList: View {
    let pullRequests: [PullRequest]
    let maxHeight: CGFloat

    var body: some View {
        FittingScrollView(maxHeight: maxHeight) {
            GroupedPullRequestList(
                groups: PullRequestGrouping.groups(pullRequests),
                summary: { items in
                    let attentionCount = items.filter(\.needsAttention).count
                    guard attentionCount > 0 else { return nil }
                    return attentionCount == 1 ? "1 PR needs attention" : "\(attentionCount) PRs need attention"
                }
            ) { pullRequest, parentNumber in
                PullRequestRow(pullRequest: pullRequest, parentNumber: parentNumber)
            }
            .padding(.vertical, 12)
        }
    }
}
