import Foundation

/// Turns what the user pasted (a GitHub pull request list link or a search) into a search query.
enum SavedSearchLink {
    static func query(from input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard looksLikeLink(trimmed) else { return requiringPullRequests(trimmed) }
        guard let query = queryFromLink(trimmed) else { return nil }
        return requiringPullRequests(query)
    }

    private static func looksLikeLink(_ input: String) -> Bool {
        let lowercased = input.lowercased()
        return lowercased.hasPrefix("https://") || lowercased.hasPrefix("http://") || lowercased.hasPrefix("github.com/")
    }

    private static func queryFromLink(_ link: String) -> String? {
        let withScheme = link.lowercased().hasPrefix("github.com/") ? "https://\(link)" : link
        guard
            let components = URLComponents(string: withScheme),
            components.host?.lowercased() == "github.com",
            let searchQuery = decodedSearchParameter(components.percentEncodedQuery)
        else { return nil }

        let path = components.path.split(separator: "/").map(String.init)
        switch path.count {
        case 1 where ["pulls", "issues"].contains(path[0]):
            return searchQuery
        case 3 where ["pulls", "issues"].contains(path[2]):
            return scoped(searchQuery, toRepository: "\(path[0])/\(path[1])")
        default:
            return nil
        }
    }

    /// GitHub writes spaces in `q` as `+`, which `URLComponents` does not decode.
    private static func decodedSearchParameter(_ percentEncodedQuery: String?) -> String? {
        let pairs = (percentEncodedQuery ?? "").split(separator: "&")
        guard let pair = pairs.first(where: { $0.hasPrefix("q=") }) else { return nil }
        let value = pair.dropFirst(2).replacingOccurrences(of: "+", with: " ").removingPercentEncoding
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func scoped(_ query: String, toRepository repository: String) -> String {
        hasQualifier(["repo", "org", "user"], in: query) ? query : "\(grouped(query)) AND repo:\(repository)"
    }

    private static func requiringPullRequests(_ query: String) -> String {
        let terms = query.lowercased().split(whereSeparator: { $0 == " " || $0 == "(" })
        let isPullRequestSearch = terms.contains("is:pr") || terms.contains("type:pr")
        return isPullRequestSearch ? query : "is:pr AND \(grouped(query))"
    }

    /// AND binds tighter than OR, so a query with a top-level OR is wrapped before
    /// another term is added; otherwise the added term only constrains one side.
    private static func grouped(_ query: String) -> String {
        hasTopLevelOr(query) ? "(\(query))" : query
    }

    private static func hasTopLevelOr(_ query: String) -> Bool {
        var depth = 0
        for term in query.split(separator: " ") {
            if depth == 0, term.uppercased() == "OR" { return true }
            depth += term.filter { $0 == "(" }.count - term.filter { $0 == ")" }.count
        }
        return false
    }

    private static func hasQualifier(_ names: [String], in query: String) -> Bool {
        let terms = query.lowercased().split(whereSeparator: { $0 == " " || $0 == "(" })
        return terms.contains { term in names.contains { term.hasPrefix("\($0):") } }
    }
}
