import Foundation

enum AppGroupContainer {
    static var sharedDefaults: UserDefaults? {
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return nil }
        return UserDefaults(suiteName: AppConfig.appGroupID)
    }

    static var directory: URL {
        // Unsigned builds (CI, tests) have no App Group container.
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConfig.appGroupID)
            ?? FileManager.default.temporaryDirectory
    }
}
