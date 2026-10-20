import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        Notifier.shared.registerAsDelegate()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        urls.forEach { LoginFlow.shared.handle($0) }
    }
}
