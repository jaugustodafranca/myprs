import Foundation
@testable import MyPRsKit
import Testing

@Suite struct PullRequestAuthorTests {
    @Test func authorSurvivesEncoding() throws {
        let pullRequest = PullRequest(
            id: "PR_1", number: 1, title: "T", url: URL(string: "https://github.com/o/r/pull/1")!, repository: "o/r",
            isDraft: false, checks: .none, review: .waiting, unansweredThreads: 0,
            updatedAt: Date(timeIntervalSince1970: 0), createdAt: Date(timeIntervalSince1970: 0),
            additions: 0, deletions: 0, changedFiles: 0, headBranch: "h", baseBranch: "main",
            hasConflicts: false, checksPassed: 0, checksTotal: 0, approvals: 0,
            authorLogin: "octocat", authorAvatarURL: URL(string: "https://avatars.githubusercontent.com/u/1?v=4")
        )
        let decoded = try JSONDecoder().decode(PullRequest.self, from: JSONEncoder().encode(pullRequest))
        #expect(decoded.authorLogin == "octocat")
        #expect(decoded.authorAvatarURL == pullRequest.authorAvatarURL)
    }

    @Test func pullRequestWithoutAuthorDecodesWithNil() throws {
        let json = """
        {"id":"PR_1","number":1,"title":"T","url":"https://github.com/o/r/pull/1","repository":"o/r","isDraft":false,
         "checks":"none","review":"waiting","unansweredThreads":0,"updatedAt":0,"createdAt":0,"additions":0,"deletions":0,
         "changedFiles":0,"headBranch":"h","baseBranch":"main","hasConflicts":false,"checksPassed":0,"checksTotal":0,"approvals":0}
        """
        let decoded = try JSONDecoder().decode(PullRequest.self, from: Data(json.utf8))
        #expect(decoded.authorLogin == nil)
        #expect(decoded.authorAvatarURL == nil)
    }
}
