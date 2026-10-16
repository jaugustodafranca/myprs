import Foundation
@testable import MyPRsKit

func makePullRequest(
    id: String = "PR_1",
    checks: CheckStatus = .passing,
    unansweredThreads: Int = 0,
    updatedAt: Date = Date(timeIntervalSince1970: 1_700_000_000),
    createdAt: Date = Date(timeIntervalSince1970: 1_699_000_000)
) -> PullRequest {
    PullRequest(
        id: id,
        number: 42,
        title: "Add widget",
        url: URL(string: "https://github.com/octo/repo/pull/42")!,
        repository: "octo/repo",
        isDraft: false,
        checks: checks,
        review: .waiting,
        unansweredThreads: unansweredThreads,
        updatedAt: updatedAt,
        createdAt: createdAt,
        additions: 10,
        deletions: 2,
        changedFiles: 3,
        headBranch: "feature/widget",
        baseBranch: "main",
        hasConflicts: false,
        checksPassed: 2,
        checksTotal: 2,
        approvals: 0
    )
}
