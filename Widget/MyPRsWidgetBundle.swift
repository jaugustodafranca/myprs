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
        StaticConfiguration(kind: "MyPRsWidget", provider: Provider()) { entry in
            EntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Open PRs")
        .description("Your open pull requests, with CI and review status.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

#Preview(as: .systemMedium) {
    MyPRsWidget()
} timeline: {
    PullRequestEntry.sample
    PullRequestEntry.empty
    PullRequestEntry.signedOut
}

#Preview(as: .systemLarge) {
    MyPRsWidget()
} timeline: {
    PullRequestEntry.sample
}
