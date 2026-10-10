import Foundation

enum PullRequestMapper {
    static func pullRequests(from data: GitHubResponse.DataPayload) -> [PullRequest] {
        data.search.nodes
            .compactMap(\.pullRequest)
            .map { pullRequest(from: $0, viewerLogin: data.viewer.login) }
    }

    private static func pullRequest(from node: GitHubResponse.PullRequestNode, viewerLogin: String) -> PullRequest {
        PullRequest(
            id: node.id,
            number: node.number,
            title: node.title,
            url: node.url,
            repository: node.repository.nameWithOwner,
            isDraft: node.isDraft,
            checks: checkStatus(from: node.commits.nodes.last?.commit.statusCheckRollup?.state),
            review: reviewStatus(from: node.reviewDecision),
            unansweredThreads: node.reviewThreads.nodes.filter { isUnanswered($0, viewerLogin: viewerLogin) }.count,
            updatedAt: node.updatedAt
        )
    }

    private static func checkStatus(from state: String?) -> CheckStatus {
        switch state {
        case "SUCCESS": .passing
        case "FAILURE", "ERROR": .failing
        case "PENDING", "EXPECTED": .running
        default: .none
        }
    }

    private static func reviewStatus(from decision: String?) -> ReviewStatus {
        switch decision {
        case "APPROVED": .approved
        case "CHANGES_REQUESTED": .changesRequested
        default: .waiting
        }
    }

    private static func isUnanswered(_ thread: GitHubResponse.ReviewThread, viewerLogin: String) -> Bool {
        guard !thread.isResolved else { return false }
        let lastAuthor = thread.comments.nodes.last?.author?.login
        return lastAuthor != viewerLogin
    }
}
