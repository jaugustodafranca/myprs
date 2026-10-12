import Foundation

extension Sequence where Element == PullRequest {
    public func sortedForDisplay() -> [PullRequest] {
        sorted { lhs, rhs in
            if lhs.needsAttention != rhs.needsAttention { return lhs.needsAttention }
            return lhs.updatedAt > rhs.updatedAt
        }
    }
}
