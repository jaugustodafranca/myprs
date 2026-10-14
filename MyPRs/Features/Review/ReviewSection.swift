import Foundation
import MyPRsKit

/// One saved search as listed in the Review tab.
struct ReviewSection: Identifiable, Equatable {
    let search: SavedSearch
    let pullRequests: [PullRequest]
    let hasFailed: Bool
    /// Not fetched yet: nothing to show and no error.
    let isLoading: Bool

    var id: UUID { search.id }
}
