import SwiftUI

struct MenuContentView: View {
    let monitor: PullRequestMonitor
    let updater: Updater
    @State private var showsSettings = false
    @State private var tab = PanelTab.open
    @State private var screenHeight = NSScreen.main?.visibleFrame.height ?? PanelSize.defaultScreenHeight

    var body: some View {
        Group {
            if monitor.isSignedIn {
                signedInContent
            } else {
                SignedOutView(monitor: monitor)
            }
        }
        .frame(width: PanelSize.width)
        .onAppear { screenHeight = NSScreen.main?.visibleFrame.height ?? PanelSize.defaultScreenHeight }
    }

    private var signedInContent: some View {
        VStack(spacing: 0) {
            PanelHeader(tab: $tab, openBadge: OpenCountBadge(PanelSummary(monitor.pullRequests)), subtitle: subtitle, isRefreshing: monitor.isRefreshing, refresh: { Task { await monitor.refresh() } }, showsSettings: $showsSettings)
            Divider()
            if showsOrganizationBanner {
                OrganizationAccessBanner(
                    access: monitor.organizationAccess,
                    checkAgain: { Task { await monitor.checkOrganizationAccess(force: true) } },
                    signInAgain: { Task { await monitor.signInAgain() } }
                )
                Divider()
            }
            tabContent
            if showsSettings {
                Divider()
                SettingsSection(monitor: monitor, updater: updater)
            } else {
                quitShortcut
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch tab {
        case .open: openContent
        case .recent: RecentPullRequestList(recent: monitor.recent, maxHeight: maxListHeight)
        }
    }

    @ViewBuilder
    private var openContent: some View {
        pullRequestList
        if let error = monitor.lastError {
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
        }
    }

    private var maxListHeight: CGFloat {
        PanelSize.maxListHeight(screenHeight: screenHeight, showsSettings: showsSettings)
    }

    private var quitShortcut: some View {
        Button("Quit") { NSApplication.shared.terminate(nil) }
            .keyboardShortcut("q")
            .frame(width: 0, height: 0)
            .opacity(0)
    }

    private var subtitle: String {
        guard tab == .open else { return "Closed and merged" }
        let summary = PanelSummary.text(for: monitor.pullRequests)
        guard let fetchedAt = monitor.snapshot?.fetchedAt else { return summary }
        let age = CompactFormat.age(from: fetchedAt)
        return age == "now" ? "\(summary) · just updated" : "\(summary) · \(age) ago"
    }

    private var showsOrganizationBanner: Bool {
        monitor.organizationAccess.needsAttention
    }

    @ViewBuilder
    private var pullRequestList: some View {
        if monitor.pullRequests.isEmpty {
            emptyState
        } else {
            PullRequestList(pullRequests: monitor.pullRequests, maxHeight: maxListHeight)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if monitor.snapshot == nil {
            Text("Loading…")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: PanelSize.emptyStateHeight)
        } else {
            VStack(spacing: 10) {
                EmptyStateView.allCaughtUp(symbolSize: 36)
                if !showsOrganizationBanner {
                    organizationAccessHint
                }
            }
            .frame(maxWidth: .infinity, minHeight: PanelSize.emptyStateHeight)
            .padding(.vertical, 8)
        }
    }

    private var organizationAccessHint: some View {
        HStack(spacing: 4) {
            Text("Missing PRs from an organization?")
                .foregroundStyle(.secondary)
            Link("Grant MyPRs access", destination: AppConfig.organizationAccessURL)
        }
        .font(.caption2)
    }
}
