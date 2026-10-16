import Foundation
import MyPRsKit

enum PullRequestMapper {
    static func pullRequests(from data: GitHubResponse.DataPayload) -> [PullRequest] {
        data.search.nodes
            .compactMap(\.pullRequest)
            .filter { GitHubURL.isTrusted($0.url) }
            .map { pullRequest(from: $0, viewerLogin: data.viewer.login) }
    }

    private static func pullRequest(from node: GitHubResponse.PullRequestNode, viewerLogin: String) -> PullRequest {
        let rollup = node.commits.nodes.last?.commit.statusCheckRollup
        let contexts = rollup?.contexts.nodes ?? []
        return PullRequest(
            id: node.id,
            number: node.number,
            title: node.title,
            url: node.url,
            repository: node.repository.nameWithOwner,
            headRepository: node.headRepository?.nameWithOwner,
            isDraft: node.isDraft,
            checks: checkStatus(from: rollup?.state),
            review: reviewStatus(from: node.reviewDecision),
            unansweredThreads: node.reviewThreads.nodes.filter { isUnanswered($0, viewerLogin: viewerLogin) }.count,
            updatedAt: node.updatedAt,
            createdAt: node.createdAt,
            additions: node.additions,
            deletions: node.deletions,
            changedFiles: node.changedFiles,
            headBranch: node.headRefName,
            baseBranch: node.baseRefName,
            hasConflicts: node.mergeable == "CONFLICTING",
            checksPassed: contexts.filter(isPassed).count,
            checksTotal: contexts.count,
            approvals: node.latestReviews.nodes.filter { $0.state == "APPROVED" }.count,
            authorLogin: node.author?.login,
            authorAvatarURL: node.author?.avatarUrl.flatMap { GitHubURL.isTrustedAvatar($0) ? $0 : nil }
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

    private static func isPassed(_ context: GitHubResponse.CheckContext) -> Bool {
        if let conclusion = context.conclusion {
            return ["SUCCESS", "NEUTRAL", "SKIPPED"].contains(conclusion)
        }
        return context.state == "SUCCESS"
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
