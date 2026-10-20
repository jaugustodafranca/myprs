import Foundation
@testable import MyPRs
import Testing
import UserNotifications

@Suite struct ReviewNotificationTests {
    @Test func separatesEventTitleAndRepository() {
        let pullRequest = makePullRequest()
        let content = Notifier.content(for: .init(kind: .checksFailed, pullRequest: pullRequest))
        #expect(content.title == "CI failed")
        #expect(content.subtitle == "Add widget")
        #expect(content.body == "octo/repo #42")
        #expect(content.userInfo["url"] as? String == pullRequest.url.absoluteString)
    }

    @Test func identifiesReviewComments() {
        let content = Notifier.content(for: .init(kind: .newUnansweredThreads, pullRequest: makePullRequest()))
        #expect(content.title == "New review comment")
        #expect(content.subtitle == "Add widget")
        #expect(content.body == "octo/repo #42")
    }

    @Test func reviewIncludesAuthorWhenKnown() {
        let content = Notifier.reviewContent(for: makePullRequest(authorLogin: "jdoe"))
        #expect(content.title == "New PR to review")
        #expect(content.subtitle == "Add widget")
        #expect(content.body == "octo/repo #42 · by jdoe")
    }

    @Test func reviewWithoutAuthorLeavesItOut() {
        #expect(Notifier.reviewContent(for: makePullRequest()).body == "octo/repo #42")
    }

    @Test func clickingEveryNotificationTargetsThePullRequest() {
        let pullRequest = makePullRequest()
        let contents = [
            Notifier.content(for: .init(kind: .checksFailed, pullRequest: pullRequest)),
            Notifier.content(for: .init(kind: .newUnansweredThreads, pullRequest: pullRequest)),
            Notifier.reviewContent(for: pullRequest)
        ]
        for content in contents {
            #expect(Notifier.destination(
                actionIdentifier: UNNotificationDefaultActionIdentifier,
                userInfo: content.userInfo
            ) == pullRequest.url)
        }
    }

    @Test func dismissingDoesNotOpenTheBrowser() {
        #expect(Notifier.destination(
            actionIdentifier: UNNotificationDismissActionIdentifier,
            userInfo: ["url": "https://github.com/acme/storefront/pull/42"]
        ) == nil)
    }

    @Test func ignoresMissingOrUntrustedDestinations() {
        let payloads: [[AnyHashable: Any]] = [
            [:], ["url": 42], ["url": "file:///tmp/example"],
            ["url": "https://example.com/pull/42"],
            ["url": "http://github.com/acme/storefront/pull/42"]
        ]
        for payload in payloads {
            #expect(Notifier.destination(
                actionIdentifier: UNNotificationDefaultActionIdentifier,
                userInfo: payload
            ) == nil)
        }
    }
}
