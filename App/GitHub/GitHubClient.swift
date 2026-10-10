import Foundation

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

    private func request(token: String) throws -> URLRequest {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["query": OpenPullRequestsQuery.text])
        return request
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { throw GitHubError.badResponse }
        if http.statusCode == 401 { throw GitHubError.unauthorized }
        guard (200..<300).contains(http.statusCode) else { throw GitHubError.badResponse }
    }
}
