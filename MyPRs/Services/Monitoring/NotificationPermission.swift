import Foundation
import UserNotifications

/// Whether macOS lets MyPRs show notifications. Once denied, only System Settings can turn them back on.
enum NotificationPermission: Equatable {
    /// Not read yet.
    case unknown
    case notDetermined
    case allowed
    case denied

    init(_ status: UNAuthorizationStatus) {
        switch status {
        case .notDetermined: self = .notDetermined
        case .authorized, .provisional: self = .allowed
        case .denied: self = .denied
        @unknown default: self = .unknown
        }
    }

    /// The system prompt can still be shown.
    var canAsk: Bool { self == .notDetermined }

    /// Notifications are not arriving: the panel says so and offers the way to turn them on.
    var needsAttention: Bool { self == .denied || self == .notDetermined }

    var bannerTitle: String {
        canAsk ? "Notifications aren't allowed yet" : "Notifications are off"
    }

    var bannerAction: String {
        canAsk ? "Allow Notifications" : "Open System Settings"
    }

    var settingsLabel: String {
        switch self {
        case .unknown: "Checking…"
        case .notDetermined: "Not allowed yet"
        case .allowed: "On"
        case .denied: "Off"
        }
    }

    /// The button next to the label in Settings; nil when notifications are on or the state is not known yet.
    var settingsAction: String? {
        switch self {
        case .allowed, .unknown: nil
        case .notDetermined: "Allow…"
        case .denied: "Open System Settings…"
        }
    }

    /// The Notifications pane of System Settings, opened on the app's own entry.
    static func systemSettingsURL(bundleID: String) -> URL {
        URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=\(bundleID)")!
    }
}
