@testable import MyPRs
import Testing

@Suite struct NewPullRequestDetectorTests {
    @Test func nothingIsNewOnTheFirstLoad() {
        #expect(NewPullRequestDetector.newPullRequests(previous: nil, current: [makePullRequest(id: "A")]).isEmpty)
    }

    @Test func reportsOnlyPullRequestsThatWereNotThereBefore() {
        let current = [makePullRequest(id: "A"), makePullRequest(id: "B"), makePullRequest(id: "C")]
        let new = NewPullRequestDetector.newPullRequests(previous: ["A"], current: current)
        #expect(new.map(\.id) == ["B", "C"])
    }

    @Test func pullRequestsThatLeftAreNotReported() {
        #expect(NewPullRequestDetector.newPullRequests(previous: ["A", "B"], current: [makePullRequest(id: "A")]).isEmpty)
    }

    @Test func emptyPreviousResultCountsAsLoaded() {
        let new = NewPullRequestDetector.newPullRequests(previous: [], current: [makePullRequest(id: "A")])
        #expect(new.map(\.id) == ["A"])
    }
}
