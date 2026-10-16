import WidgetKit

/// `Provider` falls back to the widget's own sample entry for placeholders. The preview never calls the
/// provider, but the file that defines `PullRequestEntry` has to compile.
extension PullRequestEntry {
    static let sample = PullRequestEntry(date: .now, source: .mine, snapshot: SampleData.openSnapshot, recentSnapshot: nil)
}
