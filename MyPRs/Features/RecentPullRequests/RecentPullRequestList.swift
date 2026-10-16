import MyPRsKit
import SwiftUI

struct RecentPullRequestList: View {
    let recent: RecentPullRequests
    let maxHeight: CGFloat
    @State private var hasCollapsedGroups = false

    var body: some View {
        content
                .task { await recent.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        if recent.items.isEmpty {
            emptyState
        } else {
            list
        }
    }

    private var list: some View {
        FittingScrollView(maxHeight: maxHeight) {
            LazyVStack(spacing: 0) {
                GroupedPullRequestList(
                    groups: PullRequestGrouping.groups(recent.items),
                    onCollapseChanged: { hasCollapsedGroups = $0 }
                ) { pullRequest, parentNumber in
                    ClosedPullRequestRow(pullRequest: pullRequest, parentNumber: parentNumber)
                }
                footer
                paginationSentinel
            }
        }
    }

    @ViewBuilder
    private var footer: some View {
        if recent.isLoading {
            ProgressView()
                .controlSize(.small)
                .frame(maxWidth: .infinity)
                .padding(12)
        } else if recent.hasFailed {
            retryRow
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if recent.hasFailed {
            retryRow
        } else if recent.isLoading || !recent.hasLoaded {
            ProgressView()
                .controlSize(.small)
                .frame(maxWidth: .infinity, minHeight: PanelSize.emptyStateHeight)
        } else {
            Text("No closed pull requests")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: PanelSize.emptyStateHeight)
        }
    }

    private var retryRow: some View {
        HStack(spacing: 6) {
            Text("Couldn't load.")
                .foregroundStyle(.secondary)
            Button("Retry") { Task { await recent.retry() } }
                .buttonStyle(.link)
        }
        .font(.callout)
        .frame(maxWidth: .infinity, minHeight: PanelSize.emptyStateHeight)
    }

    @ViewBuilder
    private var paginationSentinel: some View {
        if recent.hasNextPage && !recent.isLoading && !recent.hasFailed {
            Button("Load more") { loadMore() }
                .buttonStyle(.link)
                .font(.callout)
                .frame(maxWidth: .infinity)
                .padding(8)
                .id(recent.items.count)
                .onAppear {
                    if !hasCollapsedGroups { loadMore() }
                }
        }
    }

    private func loadMore() {
        guard recent.hasNextPage, !recent.isLoading, !recent.hasFailed else { return }
        Task { await recent.loadMore() }
    }
}
