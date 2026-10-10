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
            } else {
                quitShortcut
            }
        }
    }

    private var quitShortcut: some View {
        Button("Quit") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
            .frame(width: 0, height: 0)
            .opacity(0)
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
            emptyState
        } else {
            PullRequestList(pullRequests: monitor.pullRequests)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Text(monitor.snapshot == nil ? "Loading…" : "No open pull requests")
                .foregroundStyle(.secondary)
            if monitor.snapshot != nil {
                Text("Missing PRs from an organization?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Link("Grant MyPRs access", destination: AppConfig.organizationAccessURL)
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }
}
