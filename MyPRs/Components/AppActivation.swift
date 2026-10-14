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

    /// SwiftUI gives no handle to the MenuBarExtra panel; its window class name is the only marker.
    static func dismissMenuBarPanel() {
        for window in NSApp.windows where window is NSPanel && String(describing: type(of: window)).contains("MenuBarExtra") {
            window.orderOut(nil)
        }
    }
}
