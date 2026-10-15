import SwiftUI
import WidgetKit

/// A widget size in points, as macOS lays it out on a desktop.
private struct WidgetSize {
    let name: String
    let family: WidgetFamily
    let width: CGFloat
    let height: CGFloat

    static let all = [
        WidgetSize(name: "small", family: .systemSmall, width: 170, height: 170),
        WidgetSize(name: "medium", family: .systemMedium, width: 364, height: 170),
        WidgetSize(name: "large", family: .systemLarge, width: 364, height: 382),
        WidgetSize(name: "extra-large", family: .systemExtraLarge, width: 715, height: 382),
    ]
}

private struct WidgetScenario {
    let name: String
    let entry: PullRequestEntry
}

@main
enum WidgetPreview {
    /// The default content margin of a widget.
    private static let contentMargin: CGFloat = 16

    static func main() {
        MainActor.assumeIsolated { runOffscreen(renderWidgets) }
    }

    @MainActor
    private static func renderWidgets() async throws {
        let writer = try SnapshotWriter.fromCommandLine()
        for scenario in scenarios {
            for size in WidgetSize.all {
                let widget = EntryView(family: size.family, entry: scenario.entry).padding(contentMargin)
                try await writer.write(widget, named: "widget-\(scenario.name)-\(size.name)", width: size.width, height: size.height)
            }
        }
    }

    private static var scenarios: [WidgetScenario] {
        let reviewSource = WidgetSource.search(SampleData.reviewRequestedSearch)
        return [
            WidgetScenario(name: "mine", entry: entry(.mine, SampleData.openPullRequests)),
            WidgetScenario(name: "search", entry: entry(reviewSource, SampleData.reviewRequestedPullRequests)),
            WidgetScenario(name: "mine-empty", entry: entry(.mine, [])),
            WidgetScenario(name: "search-empty", entry: entry(reviewSource, [])),
            WidgetScenario(name: "signed-out", entry: PullRequestEntry(date: .now, source: .mine, snapshot: nil, isSignedOut: true)),
        ]
    }

    private static func entry(_ source: WidgetSource, _ pullRequests: [PullRequest]) -> PullRequestEntry {
        PullRequestEntry(date: .now, source: source, snapshot: SampleData.snapshot(of: pullRequests))
    }
}
