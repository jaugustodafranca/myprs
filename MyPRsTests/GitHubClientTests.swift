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

    @Test func savedSearchSendsTheQueryAsAVariableWithAdvancedSearch() async throws {
        StubURLProtocol.respond(status: 200, body: searchBody)
        let pullRequests = try await client.fetchPullRequests(matching: "is:pr AND (author:a OR author:b)", token: "abc")

        let body = try #require(StubURLProtocol.lastRequestBody)
        let json = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        let query = try #require(json["query"] as? String)
        #expect((json["variables"] as? [String: String])?["q"] == "is:pr AND (author:a OR author:b)")
        #expect(query.contains("search(query: $q, type: ISSUE_ADVANCED, first: 50)"))
        #expect(query.contains("fragment PullRequestFields on PullRequest"))
        #expect(pullRequests.map(\.number) == [7])
    }

    @Test func mapsTheAuthorAndOnlyTrustsGitHubAvatars() async throws {
        StubURLProtocol.respond(status: 200, body: searchBody)
        let pullRequest = try #require(try await client.fetchPullRequests(matching: "is:pr", token: "abc").first)
        #expect(pullRequest.authorLogin == "hubot")
        #expect(pullRequest.authorAvatarURL == URL(string: "https://avatars.githubusercontent.com/u/1?v=4"))

        StubURLProtocol.respond(status: 200, body: searchBody.replacingOccurrences(of: "avatars.githubusercontent.com", with: "evil.com"))
        let untrusted = try #require(try await client.fetchPullRequests(matching: "is:pr", token: "abc").first)
        #expect(untrusted.authorLogin == "hubot")
        #expect(untrusted.authorAvatarURL == nil)
    }

    @Test func openPullRequestsQueryKeepsItsSearch() {
        #expect(OpenPullRequestsQuery.text.contains(#"search(query: "is:pr is:open author:@me archived:false", type: ISSUE, first: 50)"#))
        #expect(OpenPullRequestsQuery.text.contains("...PullRequestFields"))
    }

    private let searchBody = #"""
    {"data":{"viewer":{"login":"me"},"search":{"nodes":[{
      "id":"PR_7","number":7,"title":"Review me","url":"https://github.com/acme/web/pull/7","isDraft":false,
      "updatedAt":"2026-09-30T08:00:00Z","createdAt":"2026-09-29T08:00:00Z","reviewDecision":null,
      "additions":1,"deletions":1,"changedFiles":1,"headRefName":"feat/x","baseRefName":"main","mergeable":"MERGEABLE",
      "author":{"login":"hubot","avatarUrl":"https://avatars.githubusercontent.com/u/1?v=4"},
      "repository":{"nameWithOwner":"acme/web"},"latestReviews":{"nodes":[]},
      "commits":{"nodes":[]},"reviewThreads":{"nodes":[]}
    }, {}]}}}
    """#

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
    nonisolated(unsafe) static var lastRequestBody: Data?

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
        Self.lastRequestBody = request.httpBody ?? request.httpBodyStream.map(Self.read)
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: nil, headerFields: Self.headers)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(Self.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func read(_ stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return data
    }
}

private extension URLSession {
    static var stubbed: URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}
