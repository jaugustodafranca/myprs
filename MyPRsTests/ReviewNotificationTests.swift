@testable import MyPRs
import Testing

@Suite struct ReviewNotificationTests {
    @Test func bodyNamesRepositoryTitleAndAuthor() {
        let pullRequest = makePullRequest(number: 7, authorLogin: "hubot")
        #expect(Notifier.reviewBody(for: pullRequest) == "octo/repo#7 · Add widget · by hubot")
    }

    @Test func bodyWithoutAuthorLeavesItOut() {
        #expect(Notifier.reviewBody(for: makePullRequest(number: 7)) == "octo/repo#7 · Add widget")
    }
}
