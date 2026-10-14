import Foundation

enum AppGroupContainer {
    static var directory: URL {
        // Unsigned builds (CI, tests) have no App Group container.
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConfig.appGroupID)
            ?? FileManager.default.temporaryDirectory
    }
}
