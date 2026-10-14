import MyPRsKit

/// Which screen the panel shows. Every open of the panel starts at `.list`.
enum PanelRoute: Hashable {
    case list
    case settings
    /// `nil` adds a new search.
    case editSearch(SavedSearch?)
}
