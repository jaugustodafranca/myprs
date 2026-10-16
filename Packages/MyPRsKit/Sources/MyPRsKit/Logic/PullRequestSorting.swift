import Foundation

extension Sequence where Element == PullRequest {
    public func sortedForDisplay() -> [PullRequest] {
        sorted { lhs, rhs in
            if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
            return lhs.id < rhs.id
        }
    }
}
