import SwiftUI

struct RecentPullRequestList: View {
    let recent: RecentPullRequests

    var body: some View {
        content
            .frame(maxHeight: 480)
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
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(recent.items) { pullRequest in
                    ClosedPullRequestRow(pullRequest: pullRequest)
                        .onAppear { loadMoreIfLast(pullRequest) }
                    Divider()
                }
                footer
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
                .frame(maxWidth: .infinity)
                .padding(24)
        } else {
            Text("No closed pull requests")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(24)
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
        .frame(maxWidth: .infinity)
        .padding(14)
    }

    private func loadMoreIfLast(_ pullRequest: ClosedPullRequest) {
        guard pullRequest.id == recent.items.last?.id else { return }
        Task { await recent.loadMore() }
    }
}
