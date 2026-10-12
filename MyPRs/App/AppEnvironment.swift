import Foundation

enum AppEnvironment {
    /// The unit tests are hosted by the app, so launching them starts the app too.
    static let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        || NSClassFromString("XCTestCase") != nil
}
