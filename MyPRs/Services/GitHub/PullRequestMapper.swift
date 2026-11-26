import Foundation
import MyPRsKit

enum PullRequestMapper {
    static func pullRequest(from node: GitHubResponse.PullRequestNode, viewerLogin: String,
                            checks: CheckSummary, mergeStateStatus: String?) -> PullRequest {
        return PullRequest(
            id: node.id,
            number: node.number,
            title: node.title,
            url: node.url,
            repository: node.repository.nameWithOwner,
            headRepository: node.headRepository?.nameWithOwner,
            isDraft: node.isDraft,
            checks: checks.status,
            review: reviewStatus(from: node.reviewDecision),
            unansweredThreads: node.reviewThreads.nodes.filter { isUnanswered($0, viewerLogin: viewerLogin) }.count,
            updatedAt: node.updatedAt,
            createdAt: node.createdAt,
            additions: node.additions,
            deletions: node.deletions,
            changedFiles: node.changedFiles,
            headBranch: node.headRefName,
            baseBranch: node.baseRefName,
            hasConflicts: node.mergeable == "CONFLICTING" || mergeStateStatus == "DIRTY",
            checksPassed: checks.passed,
            checksTotal: checks.total,
            mergeStateStatus: mergeStateStatus,
            failedChecks: checks.failures,
            approvals: node.latestReviews.nodes.filter { $0.state == "APPROVED" }.count,
            authorLogin: node.author?.login,
            authorAvatarURL: node.author?.avatarUrl.flatMap { GitHubURL.isTrustedAvatar($0) ? $0 : nil }
        )
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
