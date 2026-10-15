import Foundation
import UserNotifications

/// Whether macOS lets MyPRs show notifications. Once denied, only System Settings can turn them back on.
enum NotificationPermission: Equatable {
    case unknown
    case notDetermined
    case allowed
    case denied

    init(_ status: UNAuthorizationStatus) {
        switch status {
        case .notDetermined: self = .notDetermined
        case .authorized, .provisional, .ephemeral: self = .allowed
        case .denied: self = .denied
        @unknown default: self = .unknown
        }
    }

    /// The system prompt can still be shown.
    var canAsk: Bool { self == .notDetermined }

    /// Notifications are off: the panel tells the user and points to System Settings.
    var needsAttention: Bool { self == .denied }

    var settingsLabel: String {
        switch self {
        case .unknown: "Unknown"
        case .notDetermined: "Not allowed yet"
        case .allowed: "On"
        case .denied: "Off"
        }
    }

    /// The button next to the label in Settings; nil when notifications are on.
    var settingsAction: String? {
        switch self {
        case .allowed: nil
        case .notDetermined: "Allow…"
        case .denied, .unknown: "Open System Settings…"
        }
    }

    /// The Notifications pane of System Settings, opened on the app's own entry.
    static func systemSettingsURL(bundleID: String) -> URL {
        URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=\(bundleID)")!
    }
}
