import Foundation
import MyPRsKit
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
        #expect(OpenPullRequestsQuery.text.contains(#"search(query: "is:pr is:open author:@me archived:false sort:created-desc", type: ISSUE, first: 50)"#))
        #expect(OpenPullRequestsQuery.text.contains("...PullRequestFields"))
    }

    private typealias Context = [String: Any]

    private func job(_ name: String, _ conclusion: String, run: Int?, event: String = "pull_request",
                     start: Int = 1, hasRunDatabaseID: Bool = true) -> Context {
        var result: Context = ["__typename": "CheckRun", "name": name, "conclusion": conclusion,
                               "status": "COMPLETED", "startedAt": "2026-01-01T00:00:0\(start)Z"]
        if let run {
            let workflowRun: Context = [
                "id": "run-\(run)", "databaseId": hasRunDatabaseID ? run as Any : NSNull(),
                "runNumber": run, "event": event, "createdAt": "2026-01-01T00:00:00Z", "workflow": ["name": "Build"]
            ]
            result["checkSuite"] = ["createdAt": "2026-01-01T00:00:00Z", "workflowRun": workflowRun] as Context
        }
        return result
    }

    private func fetch(_ pages: [[Context]], mergeState: String = "CLEAN") async throws -> PullRequest {
        let search = searchBody.replacingOccurrences(of: #""commits":{"nodes":[]}"#,
            with: #""commits":{"nodes":[{"commit":{"oid":"abc"}}]}"#)
        let total = pages.reduce(0) { $0 + $1.count }
        let bodies = try pages.enumerated().map { index, nodes in
            let more = index + 1 < pages.count
            let page: Context = ["nodes": nodes, "totalCount": total,
                                 "pageInfo": ["hasNextPage": more, "endCursor": "cursor-\(index)"]]
            let commit: Context = ["oid": "abc", "statusCheckRollup": ["contexts": page]]
            let pr: Context = ["mergeStateStatus": mergeState, "commits": ["nodes": [["commit": commit]]]]
            let json = ["data": ["repository": ["pullRequest": pr]]]
            return String(decoding: try JSONSerialization.data(withJSONObject: json), as: UTF8.self)
        }
        StubURLProtocol.respond(status: 200, body: search)
        StubURLProtocol.nextBodies = bodies
        let snapshot = try await client.fetchOpenPullRequests(token: "token")
        return try #require(snapshot.pullRequests.first)
    }

    @Test func supersededRunCountsNowhere() async throws {
        let pr = try await fetch([[job("gate", "SUCCESS", run: 2), job("build", "CANCELLED", run: 1),
                                   job("gate", "FAILURE", run: 1)]])
        #expect(pr.checks == .passing)
        #expect(pr.checksPassed == 1 && pr.checksTotal == 1)
        #expect(!pr.needsAttention)
        #expect(pr.mergeStateStatus == "CLEAN")
    }

    @Test func newestFailureNamesTheJob() async throws {
        let pr = try await fetch([[job("lint", "FAILURE", run: 2), job("lint", "SUCCESS", run: 1)]])
        #expect(pr.checks == .failing && pr.needsAttention)
        #expect(pr.failedChecks == ["lint"])
    }

    @Test func rerunReplacesFailedAttempt() async throws {
        let pr = try await fetch([[job("lint", "SUCCESS", run: 1, start: 2), job("lint", "FAILURE", run: 1)]])
        #expect(pr.checks == .passing && pr.checksTotal == 1)
    }

    @Test func workflowRunsWithNullDatabaseIDsRemainDistinct() async throws {
        let old = job("old gate", "FAILURE", run: 9, hasRunDatabaseID: false)
        let current = job("build", "SUCCESS", run: 10, hasRunDatabaseID: false)
        let numbered = job("old gate", "FAILURE", run: 9)
        for checks in [[old, current], [current, old], [numbered, current]] {
            let pr = try await fetch([checks])
            #expect(pr.checks == .passing && pr.checksTotal == 1)
        }
    }

    @Test func queuedRerunWithNoStartTimeCountsOnlyTheNewestAttempt() async throws {
        var failed = job("lint", "FAILURE", run: 1)
        failed["databaseId"] = 41
        var queued = failed
        queued["conclusion"] = NSNull()
        queued["status"] = "QUEUED"
        queued["startedAt"] = NSNull()
        queued["databaseId"] = 42
        for checks in [[queued, failed], [failed, queued]] {
            let pr = try await fetch([checks])
            #expect(pr.checks == .running && pr.checksTotal == 1)
            #expect(!pr.needsAttention)
        }
        queued["databaseId"] = 40
        let pr = try await fetch([[failed, queued]])
        #expect(pr.checks == .failing && pr.checksTotal == 1)

        queued["databaseId"] = NSNull()
        let ambiguous = try await fetch([[queued, failed]])
        #expect(ambiguous.checks == .running && ambiguous.checksTotal == 1)
    }

    @Test func currentCancellationFails() async throws {
        let pr = try await fetch([[job("slow", "CANCELLED", run: 2)]])
        #expect(pr.checks == .failing && pr.failedChecks == ["slow"])
    }

    @Test func countsKeptChecksAcrossAll159Contexts() async throws {
        let first = (1...100).map { job("job-\($0)", "FAILURE", run: 1) }
        let second = (1...59).map { job("job-\($0)", "SUCCESS", run: 2) }
        let pr = try await fetch([first, second])
        #expect(pr.checks == .passing && pr.checksPassed == 59 && pr.checksTotal == 59)
        let data = try #require(StubURLProtocol.lastRequestBody)
        let body = try #require(try JSONSerialization.jsonObject(with: data) as? Context)
        let variables = try #require(body["variables"] as? Context)
        #expect(variables["after"] as? String == "cursor-0")
        #expect(variables["number"] as? Int == 7)
    }

    @Test func newestStatusShowsFailureDescription() async throws {
        let detail = "Visual differences in 188 of 2072 screens"
        let failed: Context = ["__typename": "StatusContext", "context": "Meticulous Tests", "state": "FAILURE",
                               "description": detail, "createdAt": "2026-01-02T00:00:00Z"]
        let passed: Context = ["__typename": "StatusContext", "context": "Meticulous Tests",
                               "state": "SUCCESS", "createdAt": "2026-01-01T00:00:00Z"]
        let pr = try await fetch([[failed, passed]])
        #expect(pr.checks == .failing && pr.checksTotal == 1)
        #expect(pr.failedChecks == ["Meticulous Tests — " + detail])
    }

    @Test func sameWorkflowKeepsPushAndPullRequestResults() async throws {
        let pr = try await fetch([[job("lint", "FAILURE", run: 1, event: "push"),
                                   job("lint", "SUCCESS", run: 2)]])
        #expect(pr.checks == .failing && pr.checksPassed == 1 && pr.checksTotal == 2)
    }

    @Test func latestExternalCheckPassesButConflictNeedsAttention() async throws {
        let pr = try await fetch([[job("scan", "SUCCESS", run: nil, start: 2),
                                   job("scan", "FAILURE", run: nil)]], mergeState: "DIRTY")
        #expect(pr.checks == .passing && pr.checksTotal == 1)
        #expect(pr.hasConflicts && pr.needsAttention)
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
    nonisolated(unsafe) static var nextBodies: [String] = []
    nonisolated(unsafe) private static var body = ""
    nonisolated(unsafe) static var lastRequest: URLRequest?
    nonisolated(unsafe) static var lastRequestBody: Data?

    nonisolated(unsafe) private static var headers: [String: String] = [:]

    static func respond(status: Int, body: String, headers: [String: String] = [:]) {
        nextBodies = []
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
        if !Self.nextBodies.isEmpty { Self.body = Self.nextBodies.removeFirst() }
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
