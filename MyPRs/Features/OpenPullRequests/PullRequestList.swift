import MyPRsKit
import SwiftUI

struct PullRequestList: View {
    let pullRequests: [PullRequest]
    let maxHeight: CGFloat

    var body: some View {
        FittingScrollView(maxHeight: maxHeight) {
            LazyVStack(spacing: 0) {
                ForEach(pullRequests) { pullRequest in
                    PullRequestRow(pullRequest: pullRequest)
                    if pullRequest.id != pullRequests.last?.id { Divider().padding(.leading, 32) }
                }
            }
        }
    }
}
