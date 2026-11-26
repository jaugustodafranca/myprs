import Foundation
import MyPRsKit

enum GitHubError: Error {
    case unauthorized
    case badResponse
}

struct GitHubClient {
    private static let endpoint = URL(string: "https://api.github.com/graphql")!

    var session: URLSession = .shared

    func fetchOpenPullRequests(token: String) async throws -> PullRequestSnapshot {
        let payload = try await fetchPullRequestPayload(token: token, query: OpenPullRequestsQuery.text)
        return PullRequestSnapshot(
            login: payload.viewer.login,
            pullRequests: try await pullRequests(from: payload, token: token),
            fetchedAt: Date()
        )
    }

    func fetchPullRequests(matching searchQuery: String, token: String) async throws -> [PullRequest] {
        let payload = try await fetchPullRequestPayload(token: token, query: SavedSearchQuery.text, variables: ["q": searchQuery])
        return try await pullRequests(from: payload, token: token)
    }

    private func pullRequests(from payload: GitHubResponse.DataPayload, token: String) async throws -> [PullRequest] {
        var results: [PullRequest] = []
        for node in payload.search.nodes.compactMap(\.pullRequest) where GitHubURL.isTrusted(node.url) {
            let (contexts, mergeState) = try await fetchChecks(for: node, token: token)
            results.append(PullRequestMapper.pullRequest(from: node, viewerLogin: payload.viewer.login,
                                                         checks: CheckSummary(contexts), mergeStateStatus: mergeState))
        }
        return results
    }

    private struct CheckVariables: Encodable {
        let owner: String
        let name: String
        let number: Int
        var after: String?
    }

    private func fetchChecks(for node: GitHubResponse.PullRequestNode, token: String) async throws
        -> ([GitHubResponse.CheckContext], String?) {
        guard let oid = node.commits.nodes.last?.commit.oid else { return ([], nil) }
        let repository = node.repository.nameWithOwner.split(separator: "/")
        guard repository.count == 2 else { throw GitHubError.badResponse }
        var variables = CheckVariables(owner: String(repository[0]), name: String(repository[1]), number: node.number)
        var contexts: [GitHubResponse.CheckContext] = []
        var cursors: Set<String> = []
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        while true {
            let query = try request(token: token, query: PullRequestChecksQuery.text, variables: variables)
            let (data, response) = try await session.data(for: query)
            try validate(response)
            guard let body = try? decoder.decode(PullRequestChecksResponse.self, from: data),
                  body.errors == nil, let pr = body.data?.repository?.pullRequest,
                  let commit = pr.commits.nodes.last?.commit, commit.oid == oid else {
                throw GitHubError.badResponse
            }
            guard let page = commit.statusCheckRollup?.contexts else {
                guard variables.after == nil else { throw GitHubError.badResponse }
                return ([], pr.mergeStateStatus)
            }
            contexts.append(contentsOf: page.nodes)
            guard page.pageInfo.hasNextPage else { return (contexts, pr.mergeStateStatus) }
            guard let cursor = page.pageInfo.endCursor, cursors.insert(cursor).inserted else {
                throw GitHubError.badResponse
            }
            variables.after = cursor
        }
    }

    private func fetchPullRequestPayload(token: String, query: String, variables: [String: String?] = [:]) async throws -> GitHubResponse.DataPayload {
        let (data, response) = try await session.data(for: request(token: token, query: query, variables: variables))
        try validate(response)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard
            let body = try? decoder.decode(GitHubResponse.self, from: data),
            body.errors == nil,
            let payload = body.data
        else {
            throw GitHubError.badResponse
        }
        return payload
    }

    func fetchClosedPullRequests(token: String, after cursor: String?) async throws -> ClosedPullRequestPage {
        let urlRequest = try request(token: token, query: ClosedPullRequestsQuery.text, variables: ["after": cursor])
        let (data, response) = try await session.data(for: urlRequest)
        try validate(response)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard
            let body = try? decoder.decode(ClosedPullRequestsResponse.self, from: data),
            body.errors == nil,
            let payload = body.data
        else {
            throw GitHubError.badResponse
        }
        return ClosedPullRequestMapper.page(from: payload)
    }

    func fetchOrganizationAccess(token: String) async throws -> OrganizationAccess {
        let (data, response) = try await session.data(for: request(token: token, query: OrganizationAccessQuery.text))
        try validate(response)

        guard Self.grantsOrganizationRead(response) else { return OrganizationAccess(needsReauth: true) }
        guard let body = try? JSONDecoder().decode(OrganizationAccessResponse.self, from: data) else {
            throw GitHubError.badResponse
        }
        return OrganizationAccess(restrictedOrganizations: RestrictedOrganizations.from(body))
    }

    private static func grantsOrganizationRead(_ response: URLResponse) -> Bool {
        guard let scopes = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "X-OAuth-Scopes") else { return true }
        let granted = scopes.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return !Set(granted).isDisjoint(with: ["read:org", "write:org", "admin:org"])
    }

    private func request<Variables: Encodable>(token: String, query: String, variables: Variables = [String: String?]()) throws -> URLRequest {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(RequestBody(query: query, variables: variables))
        return request
    }

    private struct RequestBody<Variables: Encodable>: Encodable {
        let query: String
        let variables: Variables
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { throw GitHubError.badResponse }
        if http.statusCode == 401 { throw GitHubError.unauthorized }
        guard (200..<300).contains(http.statusCode) else { throw GitHubError.badResponse }
    }
}
