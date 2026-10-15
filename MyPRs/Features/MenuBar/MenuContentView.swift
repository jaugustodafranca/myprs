import MyPRsKit
import SwiftUI

struct MenuContentView: View {
    let monitor: PullRequestMonitor
    let updater: Updater
    let navigation: PanelNavigation
    @State private var tab = PanelTab.open
    @State private var headerHeight: CGFloat = 0
    @State private var screenHeight = NSScreen.main?.visibleFrame.height ?? PanelSize.defaultScreenHeight

    var body: some View {
        Group {
            if monitor.isSignedIn {
                routedContent
            } else {
                SignedOutView(monitor: monitor)
            }
        }
        .frame(width: PanelSize.width)
        .background { hiddenShortcuts }
        .onAppear {
            screenHeight = NSScreen.main?.visibleFrame.height ?? PanelSize.defaultScreenHeight
            Task { await monitor.checkNotificationPermission() }
        }
    }

    @ViewBuilder
    private var routedContent: some View {
        switch navigation.route {
        case .list:
            listContent.transition(.opacity)
        case .settings:
            SettingsScreen(
                monitor: monitor,
                updater: updater,
                back: navigation.showList,
                editSearch: navigation.editSearch,
                editPrompt: navigation.editPrompt
            )
            .transition(.opacity)
        case .editSearch(let search):
            SearchEditorScreen(
                search: search,
                draft: Bindable(navigation).draft,
                save: { saved in Task { await monitor.saveSearch(saved) } },
                back: navigation.showSettings
            )
            .transition(.opacity)
        case .editPrompt:
            ReviewPromptEditorScreen(
                draft: Bindable(navigation).promptDraft,
                save: ReviewPromptStore.standard.save,
                back: navigation.showSettings
            )
            .transition(.opacity)
        }
    }

    private var listContent: some View {
        VStack(spacing: 0) {
            header
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
            tabContent
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            PanelHeader(
                tab: $tab,
                badges: badges,
                subtitle: subtitle,
                isRefreshing: monitor.isRefreshing,
                refresh: { Task { await monitor.refresh() } },
                openSettings: navigation.showSettings
            )
            Divider()
            if showsOrganizationBanner {
                OrganizationAccessBanner(
                    access: monitor.organizationAccess,
                    checkAgain: { Task { await monitor.checkOrganizationAccess(force: true) } },
                    signInAgain: { Task { await monitor.signInAgain() } }
                )
                Divider()
            }
            if monitor.notificationPermission.needsAttention {
                NotificationsOffBanner { Task { await monitor.allowNotifications() } }
                Divider()
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch tab {
        case .open: openContent
        case .recent: RecentPullRequestList(recent: monitor.recent, maxHeight: maxListHeight)
        case .review: reviewContent
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

    private var reviewContent: some View {
        ReviewPullRequestList(
            sections: reviewSections,
            hasSearches: !monitor.savedSearches.searches.isEmpty,
            showsHeaders: monitor.savedSearches.searches.count > 1,
            maxHeight: maxListHeight,
            retry: { id in Task { await monitor.refreshSearch(id) } },
            openSettings: navigation.showSettings
        )
    }

    private var reviewSections: [ReviewSection] {
        let savedSearches = monitor.savedSearches
        return ReviewSections.make(
            searches: savedSearches.searches,
            snapshots: savedSearches.snapshots,
            failedSearchIDs: savedSearches.failedSearchIDs
        )
    }

    private var badges: [PanelTab: TabCountBadge] {
        var badges: [PanelTab: TabCountBadge] = [:]
        badges[.open] = TabCountBadge(PanelSummary(monitor.pullRequests))
        badges[.review] = TabCountBadge(reviewCount: ReviewSections.pullRequestCount(in: reviewSections))
        return badges
    }

    private var maxListHeight: CGFloat {
        PanelSize.maxListHeight(screenHeight: screenHeight, chromeHeight: headerHeight)
    }

    /// ⌘Q and ⌘, while the panel is open; the panel has no menu to carry them.
    private var hiddenShortcuts: some View {
        ZStack {
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .keyboardShortcut("q")
            Button("Settings", action: navigation.showSettings)
                .keyboardShortcut(",")
        }
        .frame(width: 0, height: 0)
        .opacity(0)
        .accessibilityHidden(true)
    }

    private var subtitle: String {
        switch tab {
        case .open: openSubtitle
        case .recent: "Closed and merged"
        case .review: reviewSubtitle
        }
    }

    private var openSubtitle: String {
        let summary = PanelSummary.text(for: monitor.pullRequests)
        guard let fetchedAt = monitor.snapshot?.fetchedAt else { return summary }
        return "\(summary) · \(Self.ageText(since: fetchedAt))"
    }

    private var reviewSubtitle: String {
        let count = ReviewSections.pullRequestCount(in: reviewSections)
        let summary = count == 0 ? "Nothing to review" : "\(count) to review"
        let fetchedAt = monitor.savedSearches.snapshots.values.map(\.fetchedAt).max()
        guard let fetchedAt else { return summary }
        return "\(summary) · \(Self.ageText(since: fetchedAt))"
    }

    private static func ageText(since date: Date) -> String {
        let age = CompactFormat.age(from: date)
        return age == "now" ? "just updated" : "\(age) ago"
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
