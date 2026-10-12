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
        let (data, response) = try await session.data(for: request(token: token))
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

        return PullRequestSnapshot(
            login: payload.viewer.login,
            pullRequests: PullRequestMapper.pullRequests(from: payload),
            fetchedAt: Date()
        )
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

    private func request(token: String, query: String = OpenPullRequestsQuery.text, variables: [String: String?] = [:]) throws -> URLRequest {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(RequestBody(query: query, variables: variables))
        return request
    }

    private struct RequestBody: Encodable {
        let query: String
        let variables: [String: String?]
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { throw GitHubError.badResponse }
        if http.statusCode == 401 { throw GitHubError.unauthorized }
        guard (200..<300).contains(http.statusCode) else { throw GitHubError.badResponse }
    }
}
