import MyPRsKit

/// Which screen the panel shows. The panel keeps its route when it closes.
enum PanelRoute: Hashable {
    case list
    case settings
    /// `nil` adds a new search.
    case editSearch(SavedSearch?)
    case editPrompt
}
