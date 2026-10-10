import Foundation
import Testing

@Suite struct ChangeDetectorTests {
    @Test func reportsChecksTurningToFailing() {
        let before = [makeDetectorPullRequest(checks: .passing)]
        let after = [makeDetectorPullRequest(checks: .failing)]

        let changes = ChangeDetector.changes(from: before, to: after)

        #expect(changes.map(\.kind) == [.checksFailed])
    }

    @Test func ignoresChecksThatWereAlreadyFailing() {
        let pullRequest = makeDetectorPullRequest(checks: .failing)
        #expect(ChangeDetector.changes(from: [pullRequest], to: [pullRequest]).isEmpty)
    }

    @Test func reportsIncreasedUnansweredThreads() {
        let before = [makeDetectorPullRequest(threads: 1)]
        let after = [makeDetectorPullRequest(threads: 2)]

        #expect(ChangeDetector.changes(from: before, to: after).map(\.kind) == [.newUnansweredThreads])
    }

    @Test func ignoresDecreasedUnansweredThreads() {
        let before = [makeDetectorPullRequest(threads: 2)]
        let after = [makeDetectorPullRequest(threads: 1)]

        #expect(ChangeDetector.changes(from: before, to: after).isEmpty)
    }

    @Test func ignoresNewPullRequests() {
        let after = [makeDetectorPullRequest(checks: .failing, threads: 3)]
        #expect(ChangeDetector.changes(from: [], to: after).isEmpty)
    }
}

private func makeDetectorPullRequest(checks: CheckStatus = .passing, threads: Int = 0) -> PullRequest {
    PullRequest(
        id: "pr-1",
        number: 1,
        title: "Fix it",
        url: URL(string: "https://github.com/octo/repo/pull/1")!,
        repository: "octo/repo",
        isDraft: false,
        checks: checks,
        review: .waiting,
        unansweredThreads: threads,
        updatedAt: Date(timeIntervalSince1970: 0)
    )
}
