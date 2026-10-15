import AppKit
import Foundation
import MyPRsKit
import UserNotifications

@MainActor
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// Shows the system prompt the first time; afterwards macOS answers from its settings.
    func requestAuthorization() async {
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
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

    func notifyNewToReview(_ pullRequests: [PullRequest]) {
        for pullRequest in pullRequests {
            let content = UNMutableNotificationContent()
            content.title = "New PR to review"
            content.body = Self.reviewBody(for: pullRequest)
            content.userInfo = ["url": pullRequest.url.absoluteString]
            center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
        }
    }

    nonisolated static func reviewBody(for pullRequest: PullRequest) -> String {
        let body = "\(pullRequest.repository)#\(pullRequest.number) · \(pullRequest.title)"
        guard let author = pullRequest.authorLogin else { return body }
        return "\(body) · by \(author)"
    }

    nonisolated func userNotificationCenter(
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

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
