import Foundation

public struct PullRequestGroup<Item: GroupablePullRequest>: Identifiable {
    public let id: String
    public let items: [Item]
    public let repository: String
    public let baseBranch: String
    public let parentNumbers: [String: Int]
    public let isRelated: Bool

    public init(id: String, items: [Item], repository: String, baseBranch: String, parentNumbers: [String: Int]) {
        self.id = id
        self.items = items
        self.repository = repository
        self.baseBranch = baseBranch
        self.parentNumbers = parentNumbers
        self.isRelated = items.count > 1
    }
}
