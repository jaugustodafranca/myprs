import SwiftUI

/// Read by the initial values that `render-panel.sh` patches into `MenuContentView` and `PanelScreen`.
enum PanelPreviewState {
    static var tab = PanelTab.open
    static var collapseGroups = false
    /// The panel grows to 60% of the screen height, then scrolls. A fixed, tall screen shows the sample lists in full on every machine.
    static let screenHeight: CGFloat = 1600
}

@main
enum PanelPreview {
    static func main() {
        MainActor.assumeIsolated { runOffscreen(renderPanels) }
    }

    @MainActor
    private static func renderPanels() async throws {
        let writer = try SnapshotWriter.fromCommandLine()
        let width = PanelSize.width

        let searchDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("myprs-preview-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: searchDirectory) }
        let store = makeSearchStore(in: searchDirectory)

        let open = await makeMonitor(openPullRequests: SampleData.openPullRequests, searchStore: store)
        try await writer.write(panel(of: open, tab: .open), named: "panel-open", width: width)
        try await writer.write(panel(of: open, tab: .recent), named: "panel-recent", width: width)
        try await writer.write(panel(of: open, tab: .review), named: "panel-review", width: width)
        try await writer.write(panel(of: open, showingSettings: true), named: "panel-settings", width: width)

        PanelPreviewState.collapseGroups = true
        try await writer.write(panel(of: open, tab: .open), named: "panel-open-collapsed", width: width)
        try await writer.write(panel(of: open, tab: .recent), named: "panel-recent-collapsed", width: width)
        PanelPreviewState.collapseGroups = false

        let empty = await makeMonitor(openPullRequests: [], searchStore: store)
        try await writer.write(panel(of: empty), named: "panel-open-empty", width: width)

        let signedOut = await makeMonitor(openPullRequests: [], searchStore: store)
        signedOut.isSignedIn = false
        try await writer.write(panel(of: signedOut), named: "panel-signed-out", width: width)
    }

    @MainActor
    private static func panel(of monitor: PullRequestMonitor, tab: PanelTab = .open, showingSettings: Bool = false) -> MenuContentView {
        PanelPreviewState.tab = tab
        let navigation = PanelNavigation()
        if showingSettings { navigation.showSettings() }
        return MenuContentView(monitor: monitor, updater: Updater(), navigation: navigation)
    }

    @MainActor
    private static func makeMonitor(openPullRequests: [PullRequest], searchStore: SavedSearchStore) async -> PullRequestMonitor {
        let recent = RecentPullRequests { _ in
            ClosedPullRequestPage(pullRequests: SampleData.closedPullRequests, endCursor: nil, hasNextPage: false)
        }
        await recent.loadIfNeeded()
        return PullRequestMonitor(
            snapshot: SampleData.snapshot(of: openPullRequests),
            recent: recent,
            savedSearches: SavedSearches(store: searchStore)
        )
    }

    private static func makeSearchStore(in directory: URL) -> SavedSearchStore {
        let store = SavedSearchStore(directory: directory)
        store.saveSearches(SampleData.savedSearches)
        SampleData.searchSnapshots.forEach(store.saveSnapshot)
        return store
    }
}
