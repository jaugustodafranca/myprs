import AppIntents
import MyPRsKit
import WidgetKit

struct SelectSourceIntent: WidgetConfigurationIntent {
    static let isDiscoverable = false
    static let title: LocalizedStringResource = "Pull requests"
    static let description = IntentDescription("Choose what the widget shows.")

    @Parameter(title: "Show") var source: WidgetSourceEntity?

    init() {}
}
