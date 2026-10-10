import SwiftUI

@main
struct MyPRsApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var updater = Updater()
    @State private var monitor = PullRequestMonitor()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView(monitor: monitor, updater: updater)
        } label: {
            MenuBarIcon(pullRequests: monitor.snapshot?.pullRequests ?? [], isSignedIn: monitor.isSignedIn)
        }
        .menuBarExtraStyle(.window)
    }
}
