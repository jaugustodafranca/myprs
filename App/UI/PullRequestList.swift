import SwiftUI

struct PullRequestList: View {
    let pullRequests: [PullRequest]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(pullRequests) { pullRequest in
                    PullRequestRow(pullRequest: pullRequest)
                    if pullRequest.id != pullRequests.last?.id { Divider().padding(.leading, 32) }
                }
            }
        }
    }
}
