import AppKit
import Foundation
import MyPRsKit
import UserNotifications

final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func notify(_ changes: [PullRequestChange]) {
        for change in changes {
            let content = UNMutableNotificationContent()
            content.title = change.kind == .checksFailed ? "CI failed" : "New comment"
            content.body = "\(change.pullRequest.repository)#\(change.pullRequest.number) · \(change.pullRequest.title)"
            content.userInfo = ["url": change.pullRequest.url.absoluteString]
            center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard
            let string = response.notification.request.content.userInfo["url"] as? String,
            let url = URL(string: string),
            GitHubURL.isTrusted(url)
        else { return }
        await MainActor.run { _ = NSWorkspace.shared.open(url) }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
