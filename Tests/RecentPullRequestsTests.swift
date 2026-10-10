import Foundation
import Testing

@MainActor
@Suite struct RecentPullRequestsTests {
    private func pullRequest(_ number: Int) -> ClosedPullRequest {
        ClosedPullRequest(
            id: "PR_\(number)", number: number, title: "PR \(number)",
            url: URL(string: "https://github.com/acme/web/pull/\(number)")!,
            repository: "acme/web", headBranch: "b\(number)", baseBranch: "main",
            state: .merged, endedAt: .now, additions: 1, deletions: 1, changedFiles: 1
        )
    }

    private final class Pages {
        var cursors: [String?] = []
        var failing = false
        let pages: [ClosedPullRequestPage]

        init(_ pages: [ClosedPullRequestPage]) { self.pages = pages }

        func fetch(_ cursor: String?) throws -> ClosedPullRequestPage {
            cursors.append(cursor)
            if failing { throw GitHubError.badResponse }
            return pages[cursor == nil ? 0 : 1]
        }
    }

    private func makeRecent() -> (RecentPullRequests, Pages) {
        let pages = Pages([
            ClosedPullRequestPage(pullRequests: [pullRequest(1), pullRequest(2)], endCursor: "c1", hasNextPage: true),
            ClosedPullRequestPage(pullRequests: [pullRequest(3)], endCursor: nil, hasNextPage: false),
        ])
        return (RecentPullRequests { try pages.fetch($0) }, pages)
    }

    @Test func loadsFirstPageThenNextPageWithCursor() async {
        let (recent, pages) = makeRecent()
        await recent.loadIfNeeded()
        await recent.loadMore()
        #expect(recent.items.map(\.number) == [1, 2, 3])
        #expect(pages.cursors == [nil, "c1"])
        #expect(!recent.hasNextPage)
    }

    @Test func stopsWhenThereIsNoNextPage() async {
        let (recent, pages) = makeRecent()
        await recent.loadIfNeeded()
        await recent.loadMore()
        await recent.loadMore()
        #expect(pages.cursors.count == 2)
    }

    @Test func doesNotReloadWhileFresh() async {
        let (recent, pages) = makeRecent()
        let start = Date.now
        await recent.loadIfNeeded(now: start)
        await recent.loadIfNeeded(now: start.addingTimeInterval(9 * 60))
        #expect(pages.cursors.count == 1)
    }

    @Test func reloadsFirstPageWhenStale() async {
        let (recent, pages) = makeRecent()
        let start = Date.now
        await recent.loadIfNeeded(now: start)
        await recent.loadMore()
        await recent.loadIfNeeded(now: start.addingTimeInterval(11 * 60))
        #expect(pages.cursors == [nil, "c1", nil])
        #expect(recent.items.map(\.number) == [1, 2])
    }

    @Test func failureThenRetrySucceeds() async {
        let (recent, pages) = makeRecent()
        pages.failing = true
        await recent.loadIfNeeded()
        #expect(recent.hasFailed)
        #expect(recent.items.isEmpty)

        pages.failing = false
        await recent.retry()
        #expect(!recent.hasFailed)
        #expect(recent.items.map(\.number) == [1, 2])
    }

    @Test func clearForgetsEverything() async {
        let (recent, pages) = makeRecent()
        await recent.loadIfNeeded()
        recent.clear()
        #expect(recent.items.isEmpty)
        await recent.loadIfNeeded()
        #expect(pages.cursors == [nil, nil])
    }

    @Test func failedNextPageRetriesWithSameCursor() async {
        let (recent, pages) = makeRecent()
        await recent.loadIfNeeded()
        pages.failing = true
        await recent.loadMore()
        #expect(recent.hasFailed)
        #expect(recent.items.map(\.number) == [1, 2])

        pages.failing = false
        await recent.retry()
        #expect(pages.cursors == [nil, "c1", "c1"])
        #expect(recent.items.map(\.number) == [1, 2, 3])
    }

    @Test func concurrentLoadMoreFetchesOnce() async {
        let (recent, pages) = makeRecent()
        await recent.loadIfNeeded()
        async let first: Void = recent.loadMore()
        async let second: Void = recent.loadMore()
        _ = await (first, second)
        #expect(pages.cursors == [nil, "c1"])
    }
}
