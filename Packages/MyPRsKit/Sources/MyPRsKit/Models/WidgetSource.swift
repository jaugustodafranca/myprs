import Foundation

/// What a widget instance lists: my own open PRs, or the results of one saved search.
public enum WidgetSource: Equatable, Sendable {
    case mine
    case recent
    case search(SavedSearch)

    public static let mineID = "mine"
    public static let mineTitle = "Pull requests"
    public static let recentID = "recent"
    public static let recentTitle = "Recent pull requests"

    public var id: String {
        switch self {
        case .mine: Self.mineID
        case .recent: Self.recentID
        case .search(let search): search.id.uuidString
        }
    }

    public var title: String {
        switch self {
        case .mine: Self.mineTitle
        case .recent: Self.recentTitle
        case .search(let search): search.name
        }
    }

    /// The source stored in a widget's configuration. A missing or deleted search falls back to my PRs.
    public static func resolve(id: String?, in searches: [SavedSearch]) -> WidgetSource {
        if id == recentID { return .recent }
        guard let id, let search = searches.first(where: { $0.id.uuidString == id }) else { return .mine }
        return .search(search)
    }

    /// Every choice offered when editing a widget: my PRs first, then the searches in the user's order.
    public static func choices(in searches: [SavedSearch]) -> [WidgetSource] {
        [.mine, .recent] + searches.map(WidgetSource.search)
    }
}
