import Foundation
import MyPRsKit

/// Talks to the myprs-auth Worker, which holds the OAuth client secret.
struct AuthWorker {
    var session: URLSession = .shared
    var baseURL: URL = AppConfig.authBaseURL

    func exchange(code: String, verifier: String) async throws -> String {
        let request = post("token", body: ["code": code, "code_verifier": verifier])
        guard let (data, _) = try? await session.data(for: request),
              let body = try? JSONDecoder().decode(TokenResponse.self, from: data)
        else { throw LoginError.exchangeFailed }

        if let token = body.accessToken, !token.isEmpty { return token }
        throw body.error.map(LoginError.denied) ?? LoginError.exchangeFailed
    }

    /// Best effort: signing out must work offline, so failures are ignored.
    func revoke(_ token: String) async {
        _ = try? await session.data(for: post("revoke", body: ["access_token": token]))
    }

    private func post(_ path: String, body: [String: String]) -> URLRequest {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)
        return request
    }
}

private struct TokenResponse: Decodable {
    let accessToken: String?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case error
    }
}
