import SwiftUI

struct MenuContentView: View {
    let monitor: PullRequestMonitor
    let updater: Updater
    @State private var showsSettings = false

    var body: some View {
        Group {
            if monitor.isSignedIn {
                signedInContent
            } else {
                SignedOutView(monitor: monitor)
            }
        }
        .frame(width: 400)
    }

    private var signedInContent: some View {
        VStack(spacing: 0) {
            PanelHeader(subtitle: subtitle, isRefreshing: monitor.isRefreshing, refresh: { Task { await monitor.refresh() } }, showsSettings: $showsSettings)
            Divider()
            pullRequestList
            if let error = monitor.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
            }
            if showsSettings {
                Divider()
                SettingsSection(monitor: monitor, updater: updater)
            }
            Divider()
            Button("Quit MyPRs") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
        }
    }

    private var subtitle: String {
        let summary = PanelSummary.text(for: monitor.pullRequests)
        guard let fetchedAt = monitor.snapshot?.fetchedAt else { return summary }
        let age = CompactFormat.age(from: fetchedAt)
        return age == "now" ? "\(summary) · just updated" : "\(summary) · \(age) ago"
    }

    @ViewBuilder
    private var pullRequestList: some View {
        if monitor.pullRequests.isEmpty {
            Text(monitor.snapshot == nil ? "Loading…" : "No open pull requests")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(24)
        } else {
            PullRequestList(pullRequests: monitor.pullRequests)
        }
    }
}
