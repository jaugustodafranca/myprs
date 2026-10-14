import AppIntents
import MyPRsKit

struct WidgetSourceEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Source"
    static let defaultQuery = WidgetSourceQuery()

    let id: String
    let name: String

    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }

    init(_ source: WidgetSource) {
        id = source.id
        name = source.title
    }
}

struct WidgetSourceQuery: EntityQuery {
    func suggestedEntities() async throws -> [WidgetSourceEntity] {
        WidgetSource.choices(in: SavedSearchStore.shared.loadSearches()).map(WidgetSourceEntity.init)
    }

    func defaultResult() async -> WidgetSourceEntity? {
        WidgetSourceEntity(.mine)
    }

    func entities(for identifiers: [String]) async throws -> [WidgetSourceEntity] {
        let searches = SavedSearchStore.shared.loadSearches()
        return identifiers.map { WidgetSourceEntity(WidgetSource.resolve(id: $0, in: searches)) }
    }
}
