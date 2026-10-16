import Foundation
import MyPRsKit
import Testing

@Suite struct ReviewPromptStoreTests {
    @Test func savingAndResettingKeepsTheWidgetCacheInSync() {
        let preferences = isolatedDefaults()
        let widgetCache = isolatedDefaults()
        let store = ReviewPromptStore(defaults: preferences, cacheDefaults: widgetCache)

        store.save("Review {{repo}} carefully")
        #expect(store.customTemplate == "Review {{repo}} carefully")
        #expect(widgetCache.string(forKey: "reviewPromptTemplate") == "Review {{repo}} carefully")

        store.reset()
        #expect(store.customTemplate == nil)
        #expect(widgetCache.string(forKey: "reviewPromptTemplate") == nil)
    }

    @Test func migrationCopiesTheExistingAppPreferenceIntoTheWidgetCache() {
        let preferences = isolatedDefaults()
        let widgetCache = isolatedDefaults()
        preferences.set("Existing custom prompt", forKey: "reviewPromptTemplate")
        let store = ReviewPromptStore(defaults: preferences, cacheDefaults: widgetCache)

        store.synchronizeAppGroup()

        #expect(widgetCache.string(forKey: "reviewPromptTemplate") == "Existing custom prompt")
    }

    private func isolatedDefaults() -> UserDefaults {
        UserDefaults(suiteName: "ReviewPromptStoreTests-\(UUID().uuidString)")!
    }
}
