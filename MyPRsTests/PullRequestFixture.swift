import Foundation
import MyPRsKit

func makePullRequest(
    id: String = "PR_1",
    checks: CheckStatus = .passing,
    unansweredThreads: Int = 0,
    updatedAt: Date = Date(timeIntervalSince1970: 1_700_000_000),
    number: Int = 42,
    repository: String = "octo/repo",
    checksPassed: Int = 2,
    checksTotal: Int = 2,
    authorLogin: String? = nil
) -> PullRequest {
    PullRequest(
        id: id,
        number: number,
        title: "Add widget",
        url: URL(string: "https://github.com/octo/repo/pull/42")!,
        repository: repository,
        isDraft: false,
        checks: checks,
        review: .waiting,
        unansweredThreads: unansweredThreads,
        updatedAt: updatedAt,
        createdAt: Date(timeIntervalSince1970: 1_699_000_000),
        additions: 10,
        deletions: 2,
        changedFiles: 3,
        headBranch: "feature/widget",
        baseBranch: "main",
        hasConflicts: false,
        checksPassed: checksPassed,
        checksTotal: checksTotal,
        approvals: 0,
        authorLogin: authorLogin
    )
}
