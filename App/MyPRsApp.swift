import SwiftUI

@main
struct MyPRsApp: App {
    @State private var updater = Updater()
    @State private var monitor = PullRequestMonitor()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(monitor: monitor, updater: updater)
        } label: {
            MenuBarIcon(pullRequests: monitor.snapshot?.pullRequests ?? [])
        }
        .menuBarExtraStyle(.window)
    }
}
