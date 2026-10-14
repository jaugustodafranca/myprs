import AppKit
import Foundation
import Sparkle

@MainActor
@Observable
final class Updater: NSObject {
    private(set) var canCheckForUpdates = false

    private var controller: SPUStandardUpdaterController!
    private var observation: NSKeyValueObservation?

    override init() {
        super.init()
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: self
        )
        observation = controller.updater.observe(\.canCheckForUpdates, options: [.initial, .new]) { [weak self] _, change in
            let canCheck = change.newValue ?? false
            Task { @MainActor in self?.canCheckForUpdates = canCheck }
        }
    }

    func checkForUpdates() {
        AppActivation.dismissMenuBarPanel()
        AppActivation.bringToFront()
        controller.checkForUpdates(nil)
    }
}

// Sparkle's gentle reminders pattern for apps without a Dock icon:
// https://sparkle-project.org/documentation/gentle-reminders/
extension Updater: SPUStandardUserDriverDelegate {
    nonisolated var supportsGentleScheduledUpdateReminders: Bool { true }

    nonisolated func standardUserDriverShouldHandleShowingScheduledUpdate(
        _ update: SUAppcastItem,
        andInImmediateFocus immediateFocus: Bool
    ) -> Bool {
        true
    }

    nonisolated func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool,
        forUpdate update: SUAppcastItem,
        state: SPUUserUpdateState
    ) {
        Task { @MainActor in
            NSApp.setActivationPolicy(.regular)
            AppActivation.bringToFront()
        }
    }

    nonisolated func standardUserDriverWillFinishUpdateSession() {
        Task { @MainActor in NSApp.setActivationPolicy(.accessory) }
    }
}
