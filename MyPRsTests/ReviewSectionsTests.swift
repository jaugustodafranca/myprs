import Foundation
import MyPRsKit
@testable import MyPRs
import Testing

@Suite struct ReviewSectionsTests {
    private let first = SavedSearch(name: "First", query: "is:pr a")
    private let second = SavedSearch(name: "Second", query: "is:pr b")

    private func snapshot(_ search: SavedSearch, _ ids: [String]) -> SavedSearchSnapshot {
        SavedSearchSnapshot(searchID: search.id, pullRequests: ids.map { makePullRequest(id: $0) }, fetchedAt: .now)
    }

    @Test func keepsTheSearchOrderAndGitHubsOrder() {
        let sections = ReviewSections.make(
            searches: [first, second],
            snapshots: [first.id: snapshot(first, ["B", "A"]), second.id: snapshot(second, ["C"])],
            failedSearchIDs: []
        )
        #expect(sections.map(\.search.name) == ["First", "Second"])
        #expect(sections[0].pullRequests.map(\.id) == ["B", "A"])
    }

    @Test func listsAPullRequestUnderTheFirstSearchOnly() {
        let sections = ReviewSections.make(
            searches: [first, second],
            snapshots: [first.id: snapshot(first, ["A", "B"]), second.id: snapshot(second, ["B", "C"])],
            failedSearchIDs: []
        )
        #expect(sections[1].pullRequests.map(\.id) == ["C"])
        #expect(ReviewSections.pullRequestCount(in: sections) == 3)
    }

    @Test func leavesOutSearchesWithNothingToShow() {
        let sections = ReviewSections.make(
            searches: [first, second],
            snapshots: [first.id: snapshot(first, ["A"]), second.id: snapshot(second, ["A"])],
            failedSearchIDs: []
        )
        #expect(sections.map(\.search.name) == ["First"])
    }

    @Test func keepsFailedAndNotYetLoadedSearches() {
        let sections = ReviewSections.make(searches: [first, second], snapshots: [:], failedSearchIDs: [second.id])
        #expect(sections.map(\.isLoading) == [true, false])
        #expect(sections.map(\.hasFailed) == [false, true])
    }

    @Test func failedSearchKeepsItsLastResult() {
        let sections = ReviewSections.make(searches: [first], snapshots: [first.id: snapshot(first, ["A"])], failedSearchIDs: [first.id])
        #expect(sections.first?.hasFailed == true)
        #expect(sections.first?.pullRequests.map(\.id) == ["A"])
    }
}
