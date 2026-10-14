import Foundation
import MyPRsKit

enum ReviewSections {
    /// One section per search, in the user's order. A pull request found by several
    /// searches is listed under the first one only. Searches with nothing to show are left out.
    static func make(
        searches: [SavedSearch],
        snapshots: [UUID: SavedSearchSnapshot],
        failedSearchIDs: Set<UUID>
    ) -> [ReviewSection] {
        var listedIDs = Set<String>()
        return searches.compactMap { search in
            let snapshot = snapshots[search.id]
            let pullRequests = (snapshot?.pullRequests ?? []).filter { listedIDs.insert($0.id).inserted }
            let hasFailed = failedSearchIDs.contains(search.id)
            let isLoading = snapshot == nil && !hasFailed
            guard !pullRequests.isEmpty || hasFailed || isLoading else { return nil }
            return ReviewSection(search: search, pullRequests: pullRequests, hasFailed: hasFailed, isLoading: isLoading)
        }
    }

    static func pullRequestCount(in sections: [ReviewSection]) -> Int {
        sections.reduce(0) { $0 + $1.pullRequests.count }
    }
}
