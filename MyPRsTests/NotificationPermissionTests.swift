@testable import MyPRs
import Testing
import UserNotifications

@Suite struct NotificationPermissionTests {
    @Test func mapsEveryAuthorizationStatus() {
        #expect(NotificationPermission(.notDetermined) == .notDetermined)
        #expect(NotificationPermission(.authorized) == .allowed)
        #expect(NotificationPermission(.provisional) == .allowed)
        #expect(NotificationPermission(.denied) == .denied)
    }

    @Test func onlyAnUnaskedPermissionCanPrompt() {
        #expect(NotificationPermission.notDetermined.canAsk)
        #expect(!NotificationPermission.denied.canAsk)
        #expect(!NotificationPermission.allowed.canAsk)
    }

    @Test func deniedAndUnaskedNeedAttention() {
        #expect(NotificationPermission.denied.needsAttention)
        #expect(NotificationPermission.notDetermined.needsAttention)
        #expect(!NotificationPermission.allowed.needsAttention)
        #expect(!NotificationPermission.unknown.needsAttention)
    }

    @Test func bannerPromptsWhenItCanAndOpensSettingsOtherwise() {
        #expect(NotificationPermission.notDetermined.bannerTitle == "Notifications aren't allowed yet")
        #expect(NotificationPermission.notDetermined.bannerAction == "Allow Notifications")
        #expect(NotificationPermission.denied.bannerTitle == "Notifications are off")
        #expect(NotificationPermission.denied.bannerAction == "Open System Settings")
    }

    @Test func settingsRowOffersTheRightAction() {
        #expect(NotificationPermission.allowed.settingsLabel == "On")
        #expect(NotificationPermission.allowed.settingsAction == nil)
        #expect(NotificationPermission.unknown.settingsLabel == "Checking…")
        #expect(NotificationPermission.unknown.settingsAction == nil)
        #expect(NotificationPermission.notDetermined.settingsAction == "Allow…")
        #expect(NotificationPermission.denied.settingsLabel == "Off")
        #expect(NotificationPermission.denied.settingsAction == "Open System Settings…")
    }

    @Test func systemSettingsLinkOpensTheAppsEntry() {
        let url = NotificationPermission.systemSettingsURL(bundleID: "com.example.app")
        #expect(url.absoluteString == "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=com.example.app")
    }
}
