import MyPRsKit

enum ClosedPullRequestMapper {
    static func page(from data: ClosedPullRequestsResponse.DataPayload) -> ClosedPullRequestPage {
        ClosedPullRequestPage(
            pullRequests: data.search.nodes
                .compactMap(\.pullRequest)
                .filter { GitHubURL.isTrusted($0.url) }
                .compactMap(pullRequest(from:)),
            endCursor: data.search.pageInfo.endCursor,
            hasNextPage: data.search.pageInfo.hasNextPage
        )
    }

    private static func pullRequest(from node: ClosedPullRequestsResponse.PullRequestNode) -> ClosedPullRequest? {
        let state: ClosedState = node.state == "MERGED" ? .merged : .closed
        guard let endedAt = state == .merged ? node.mergedAt : node.closedAt else { return nil }
        return ClosedPullRequest(
            id: node.id,
            number: node.number,
            title: node.title,
            url: node.url,
            repository: node.repository.nameWithOwner,
            headBranch: node.headRefName,
            baseBranch: node.baseRefName,
            state: state,
            endedAt: endedAt,
            additions: node.additions,
            deletions: node.deletions,
            changedFiles: node.changedFiles,
            createdAt: node.createdAt,
            headRepository: node.headRepository?.nameWithOwner
        )
    }
}
