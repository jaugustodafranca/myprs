import Foundation
import MyPRsKit

/// What the search editor holds while the user types.
struct SavedSearchDraft: Equatable {
    var name: String
    var linkOrQuery: String
    var notifies: Bool

    init(name: String = "", linkOrQuery: String = "", notifies: Bool = false) {
        self.name = name
        self.linkOrQuery = linkOrQuery
        self.notifies = notifies
    }

    init(_ search: SavedSearch) {
        self.init(name: search.name, linkOrQuery: search.query, notifies: search.notifies)
    }

    var query: String? { SavedSearchLink.query(from: linkOrQuery) }

    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var canSave: Bool { !trimmedName.isEmpty && query != nil }

    func savedSearch(id: UUID = UUID()) -> SavedSearch? {
        guard canSave, let query else { return nil }
        return SavedSearch(id: id, name: trimmedName, query: query, notifies: notifies)
    }
}
