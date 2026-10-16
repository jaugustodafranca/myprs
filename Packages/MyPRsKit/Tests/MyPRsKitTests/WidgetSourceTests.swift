import Foundation
@testable import MyPRsKit
import Testing

@Suite struct WidgetSourceTests {
    private let reviews = SavedSearch(name: "Review requested", query: "is:pr")
    private let mentions = SavedSearch(name: "Mentions", query: "mentions:@me")

    @Test func nothingChosenShowsMyPullRequests() {
        #expect(WidgetSource.resolve(id: nil, in: [reviews]) == .mine)
    }

    @Test func mineIDResolvesToMine() {
        #expect(WidgetSource.resolve(id: WidgetSource.mineID, in: [reviews]) == .mine)
    }

    @Test func recentIDResolvesToRecent() {
        #expect(WidgetSource.resolve(id: WidgetSource.recentID, in: [reviews]) == .recent)
    }

    @Test func searchIDResolvesToThatSearch() {
        let source = WidgetSource.resolve(id: mentions.id.uuidString, in: [reviews, mentions])
        #expect(source == .search(mentions))
        #expect(source.title == "Mentions")
    }

    @Test func deletedSearchFallsBackToMyPullRequests() {
        #expect(WidgetSource.resolve(id: mentions.id.uuidString, in: [reviews]) == .mine)
    }

    @Test func renamedSearchResolvesWithItsNewName() {
        var renamed = reviews
        renamed.name = "For me"
        #expect(WidgetSource.resolve(id: reviews.id.uuidString, in: [renamed]).title == "For me")
    }

    @Test func idRoundTripsThroughResolve() {
        for source in WidgetSource.choices(in: [reviews, mentions]) {
            #expect(WidgetSource.resolve(id: source.id, in: [reviews, mentions]) == source)
        }
    }

    @Test func choicesListMineThenSearchesInOrder() {
        let titles = WidgetSource.choices(in: [reviews, mentions]).map(\.title)
        #expect(titles == ["Pull requests", "Recent pull requests", "Review requested", "Mentions"])
    }

    @Test func reviewPillCountsAndHidesWhenEmpty() {
        #expect(StatusPill(toReview: 3)?.text == "3 to review")
        #expect(StatusPill(toReview: 3)?.tone == .neutral)
        #expect(StatusPill(toReview: 0) == nil)
    }
}
