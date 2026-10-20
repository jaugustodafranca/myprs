import AppKit
import Foundation
import MyPRsKit
import UserNotifications

@MainActor
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    static let shared = Notifier()
    private let center = UNUserNotificationCenter.current()

    func registerAsDelegate() {
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
            let content = Self.content(for: change)
            center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
        }
    }

    func notifyNewToReview(_ pullRequests: [PullRequest]) {
        for pullRequest in pullRequests {
            let content = Self.reviewContent(for: pullRequest)
            center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
        }
    }

    nonisolated static func content(for change: PullRequestChange) -> UNMutableNotificationContent {
        let content = baseContent(for: change.pullRequest)
        content.title = change.kind == .checksFailed ? "CI failed" : "New review comment"
        return content
    }

    nonisolated static func reviewContent(for pullRequest: PullRequest) -> UNMutableNotificationContent {
        let content = baseContent(for: pullRequest)
        content.title = "New PR to review"
        if let author = pullRequest.authorLogin {
            content.body += " · by \(author)"
        }
        return content
    }

    nonisolated private static func baseContent(for pullRequest: PullRequest) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.subtitle = pullRequest.title
        content.body = "\(pullRequest.repository) #\(pullRequest.number)"
        content.userInfo = ["url": pullRequest.url.absoluteString]
        return content
    }

    nonisolated static func destination(
        actionIdentifier: String,
        userInfo: [AnyHashable: Any]
    ) -> URL? {
        guard
            actionIdentifier == UNNotificationDefaultActionIdentifier,
            let string = userInfo["url"] as? String,
            let url = URL(string: string),
            GitHubURL.isTrusted(url)
        else { return nil }
        return url
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let url = Self.destination(
            actionIdentifier: response.actionIdentifier,
            userInfo: response.notification.request.content.userInfo
        ) else { return }
        await MainActor.run { _ = NSWorkspace.shared.open(url) }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
