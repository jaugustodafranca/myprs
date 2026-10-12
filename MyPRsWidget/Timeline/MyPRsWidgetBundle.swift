import MyPRsKit
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
        StaticConfiguration(kind: AppConfig.widgetKind, provider: Provider()) { entry in
            EntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Open PRs")
        .description("Your open pull requests, with CI and review status.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

#Preview("Small", as: .systemSmall) {
    MyPRsWidget()
} timeline: {
    PullRequestEntry.sample
    PullRequestEntry.calm
    PullRequestEntry.empty
    PullRequestEntry.signedOut
}

#Preview("Medium", as: .systemMedium) {
    MyPRsWidget()
} timeline: {
    PullRequestEntry.sample
    PullRequestEntry.empty
}

#Preview("Large", as: .systemLarge) {
    MyPRsWidget()
} timeline: {
    PullRequestEntry.sample
}

#Preview("Extra large", as: .systemExtraLarge) {
    MyPRsWidget()
} timeline: {
    PullRequestEntry.sample
}
