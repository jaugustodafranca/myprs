import Foundation
import Testing

@Suite(.serialized) struct GitHubClientTests {
    private let client = GitHubClient(session: .stubbed)

    @Test func throwsUnauthorizedOn401() async {
        StubURLProtocol.respond(status: 401, body: #"{"message":"Bad credentials"}"#)
        await #expect(throws: GitHubError.unauthorized) {
            try await client.fetchOpenPullRequests(token: "revoked")
        }
    }

    @Test func throwsBadResponseOnOtherHTTPErrors() async {
        StubURLProtocol.respond(status: 502, body: "")
        await #expect(throws: GitHubError.badResponse) {
            try await client.fetchOpenPullRequests(token: "token")
        }
    }

    @Test func throwsBadResponseOnGraphQLErrors() async {
        StubURLProtocol.respond(status: 200, body: #"{"errors":[{"message":"Something failed"}]}"#)
        await #expect(throws: GitHubError.badResponse) {
            try await client.fetchOpenPullRequests(token: "token")
        }
    }

    @Test func sendsBearerToken() async throws {
        StubURLProtocol.respond(status: 200, body: #"{"data":{"viewer":{"login":"me"},"search":{"nodes":[]}}}"#)
        let snapshot = try await client.fetchOpenPullRequests(token: "abc")
        #expect(snapshot.login == "me")
        #expect(StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "Authorization") == "bearer abc")
    }
}

private final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) private static var status = 200
    nonisolated(unsafe) private static var body = ""
    nonisolated(unsafe) static var lastRequest: URLRequest?

    static func respond(status: Int, body: String) {
        self.status = status
        self.body = body
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(Self.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private extension URLSession {
    static var stubbed: URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}
