import Foundation
@testable import MyPRsKit
import Testing

@Suite struct CompactFormatTests {
    @Test(arguments: [(0, "0"), (999, "999"), (1000, "1k"), (1234, "1.2k"), (1999, "1.9k"), (12_500, "12.5k"), (150_000, "150k")])
    func countsAreCompact(value: Int, expected: String) {
        #expect(CompactFormat.count(value) == expected)
    }

    @Test(arguments: [(30.0, "now"), (300.0, "5m"), (7200.0, "2h"), (86_400.0 * 2, "2d"), (86_400.0 * 15, "2w"), (86_400.0 * 400, "1y")])
    func agesAreShort(seconds: Double, expected: String) {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        #expect(CompactFormat.age(from: now.addingTimeInterval(-seconds), to: now) == expected)
    }

    @Test func futureDatesCountAsNow() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        #expect(CompactFormat.age(from: now.addingTimeInterval(60), to: now) == "now")
    }
}

@Suite struct PanelSummaryTests {
    @Test func emptyList() {
        #expect(PanelSummary.text(for: []) == "No open pull requests")
    }

    @Test func countsOpenFailingAndToAnswer() {
        let prs = [
            makePullRequest(id: "1", checks: .failing),
            makePullRequest(id: "2", unansweredThreads: 2),
            makePullRequest(id: "3"),
        ]
        #expect(PanelSummary.text(for: prs) == "3 open · 1 failing · 1 to answer")
    }

    @Test func omitsZeroCounts() {
        #expect(PanelSummary.text(for: [makePullRequest()]) == "1 open")
    }
}
