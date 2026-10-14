import MyPRsKit
import SwiftUI

struct ReviewPullRequestList: View {
    let sections: [ReviewSection]
    let hasSearches: Bool
    let showsHeaders: Bool
    let maxHeight: CGFloat
    let retry: (UUID) -> Void
    let openSettings: () -> Void

    var body: some View {
        if !hasSearches {
            noSearches
        } else if sections.isEmpty {
            EmptyStateView.nothingToReview(symbolSize: 36)
                .frame(maxWidth: .infinity, minHeight: PanelSize.emptyStateHeight)
                .padding(.vertical, 8)
        } else {
            list
        }
    }

    private var list: some View {
        FittingScrollView(maxHeight: maxHeight) {
            LazyVStack(spacing: 0) {
                ForEach(sections) { section in
                    if showsHeaders {
                        ReviewSectionHeader(name: section.search.name, count: section.pullRequests.count)
                    }
                    if section.hasFailed {
                        ReviewRetryRow(searchName: section.search.name) { retry(section.id) }
                    }
                    if section.isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                    }
                    rows(of: section)
                    if section.id != sections.last?.id { Divider() }
                }
            }
        }
    }

    @ViewBuilder
    private func rows(of section: ReviewSection) -> some View {
        ForEach(section.pullRequests) { pullRequest in
            PullRequestRow(pullRequest: pullRequest, showsAuthor: true)
            if pullRequest.id != section.pullRequests.last?.id { Divider().padding(.leading, 32) }
        }
    }

    private var noSearches: some View {
        VStack(spacing: 10) {
            EmptyStateView(
                symbol: "line.3.horizontal.decrease.circle",
                tint: .secondary,
                title: "No searches",
                subtitle: "Add a GitHub search to list pull requests to review.",
                symbolSize: 36
            )
            Button("Add Search…", action: openSettings)
                .controlSize(.small)
        }
        .frame(maxWidth: .infinity, minHeight: PanelSize.emptyStateHeight)
        .padding(.vertical, 8)
    }
}
