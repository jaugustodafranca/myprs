import Foundation
@testable import MyPRs
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

    private let restrictedBody = #"{"data":{"viewer":{"organizations":{"nodes":[{"login":"locked","repositories":null}]}}},"errors":[{"type":"FORBIDDEN","message":"OAuth App access restrictions","path":["viewer","organizations","nodes",0,"repositories"]}]}"#

    @Test func reportsRestrictedOrganizations() async throws {
        StubURLProtocol.respond(status: 200, body: restrictedBody, headers: ["X-OAuth-Scopes": "repo, read:org"])
        let access = try await client.fetchOrganizationAccess(token: "token")
        #expect(access == OrganizationAccess(restrictedOrganizations: ["locked"]))
    }

    @Test func asksToSignInAgainWithoutReadOrgScope() async throws {
        StubURLProtocol.respond(status: 200, body: restrictedBody, headers: ["X-OAuth-Scopes": "repo"])
        let access = try await client.fetchOrganizationAccess(token: "token")
        #expect(access == OrganizationAccess(needsReauth: true))
    }
}

private final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) private static var status = 200
    nonisolated(unsafe) private static var body = ""
    nonisolated(unsafe) static var lastRequest: URLRequest?

    nonisolated(unsafe) private static var headers: [String: String] = [:]

    static func respond(status: Int, body: String, headers: [String: String] = [:]) {
        self.status = status
        self.body = body
        self.headers = headers
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: nil, headerFields: Self.headers)!
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
