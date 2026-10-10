import SwiftUI
import WidgetKit

@main
struct MyPRsWidgetBundle: WidgetBundle {
    var body: some Widget {
        MyPRsWidget()
    }
}

struct MyPRsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MyPRsWidget", provider: PlaceholderProvider()) { _ in
            Text("MyPRs")
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct PlaceholderEntry: TimelineEntry {
    let date = Date()
}

struct PlaceholderProvider: TimelineProvider {
    func placeholder(in context: Context) -> PlaceholderEntry { PlaceholderEntry() }

    func getSnapshot(in context: Context, completion: @escaping (PlaceholderEntry) -> Void) {
        completion(PlaceholderEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PlaceholderEntry>) -> Void) {
        completion(Timeline(entries: [PlaceholderEntry()], policy: .never))
    }
}
