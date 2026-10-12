enum OrganizationAccessQuery {
    static let text = """
    query {
      viewer {
        organizations(first: 100) {
          nodes { login repositories(first: 1) { totalCount } }
        }
      }
    }
    """
}

struct OrganizationAccessResponse: Decodable {
    let data: DataPayload?
    let errors: [GraphQLError]?

    struct DataPayload: Decodable {
        let viewer: Viewer?
    }

    struct Viewer: Decodable {
        let organizations: Organizations?
    }

    struct Organizations: Decodable {
        let nodes: [Organization?]
    }

    struct Organization: Decodable {
        let login: String
    }

    struct GraphQLError: Decodable {
        let type: String?
        let message: String
        let path: [PathElement]?
    }

    enum PathElement: Decodable, Equatable {
        case key(String)
        case index(Int)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let index = try? container.decode(Int.self) {
                self = .index(index)
            } else {
                self = .key(try container.decode(String.self))
            }
        }
    }
}

enum RestrictedOrganizations {
    static func from(_ response: OrganizationAccessResponse) -> [String] {
        guard let organizations = response.data?.viewer?.organizations?.nodes else { return [] }
        let indices = (response.errors ?? []).compactMap(restrictedIndex)
        return indices
            .compactMap { organizations.indices.contains($0) ? organizations[$0]?.login : nil }
            .uniqued()
    }

    private static func restrictedIndex(of error: OrganizationAccessResponse.GraphQLError) -> Int? {
        guard error.type == "FORBIDDEN", error.message.contains("OAuth App access restrictions") else { return nil }
        let path = error.path ?? []
        guard path.count >= 4, path[..<3] == [.key("viewer"), .key("organizations"), .key("nodes")] else { return nil }
        guard case .index(let index) = path[3] else { return nil }
        return index
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
