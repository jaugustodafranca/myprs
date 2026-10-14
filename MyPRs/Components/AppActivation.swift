import AppKit

/// A menu bar (LSUIElement) app is never active on its own, so its windows open behind other apps.
@MainActor
enum AppActivation {
    static func bringToFront() {
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    /// SwiftUI gives no handle to the MenuBarExtra panel, so it is found by its private class name.
    /// If Apple renames it nothing matches and the panel simply stays open.
    static func dismissMenuBarPanel() {
        for window in NSApp.windows where isMenuBarPanel(window) {
            window.orderOut(nil)
        }
    }

    static func isMenuBarPanel(_ window: NSWindow) -> Bool {
        window is NSPanel && String(describing: type(of: window)).contains("MenuBarExtra")
    }
}
