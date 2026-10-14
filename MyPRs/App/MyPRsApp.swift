import SwiftUI

@main
enum AppLauncher {
    static func main() {
        if AppEnvironment.isRunningTests {
            TestHostApp.main()
        } else {
            MyPRsApp.main()
        }
    }
}

/// Shown while the tests run: it never touches the Keychain, App Group, notifications, Sparkle or widgets.
struct TestHostApp: App {
    var body: some Scene {
        Settings { EmptyView() }
    }
}

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
