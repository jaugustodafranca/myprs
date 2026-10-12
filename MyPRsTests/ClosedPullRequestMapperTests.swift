import Foundation
import MyPRsKit
@testable import MyPRs
import Testing

@Suite struct ClosedPullRequestMapperTests {
    private let page: ClosedPullRequestPage

    init() throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(ClosedPullRequestsResponse.self, from: Data(fixture.utf8))
        page = ClosedPullRequestMapper.page(from: try #require(response.data))
    }

    @Test func skipsNodesThatAreNotPullRequests() {
        #expect(page.pullRequests.map(\.number) == [12, 11])
    }

    @Test func mapsMergedPullRequest() {
        let merged = page.pullRequests[0]
        #expect(merged.id == "PR_12")
        #expect(merged.title == "Merged work")
        #expect(merged.url == URL(string: "https://github.com/acme/web/pull/12"))
        #expect(merged.repository == "acme/web")
        #expect(merged.headBranch == "feature/merged")
        #expect(merged.baseBranch == "main")
        #expect(merged.state == .merged)
        #expect(merged.endedAt == Date(timeIntervalSince1970: 1_790_812_800))
        #expect(merged.additions == 40)
        #expect(merged.deletions == 5)
        #expect(merged.changedFiles == 3)
    }

    @Test func mapsClosedPullRequestUsingClosedAt() {
        let closed = page.pullRequests[1]
        #expect(closed.state == .closed)
        #expect(closed.endedAt == Date(timeIntervalSince1970: 1_790_726_400))
    }

    @Test func mapsPageInfo() {
        #expect(page.hasNextPage)
        #expect(page.endCursor == "cursor-2")
    }
}

private let fixture = """
{
  "data": {
    "search": {
      "pageInfo": { "hasNextPage": true, "endCursor": "cursor-2" },
      "nodes": [
        {
          "id": "PR_12", "number": 12, "title": "Merged work",
          "url": "https://github.com/acme/web/pull/12", "state": "MERGED",
          "mergedAt": "2026-10-01T00:00:00Z", "closedAt": "2026-10-01T00:00:00Z",
          "additions": 40, "deletions": 5, "changedFiles": 3,
          "headRefName": "feature/merged", "baseRefName": "main",
          "repository": { "nameWithOwner": "acme/web" }
        },
        {},
        {
          "id": "PR_11", "number": 11, "title": "Abandoned work",
          "url": "https://github.com/acme/web/pull/11", "state": "CLOSED",
          "mergedAt": null, "closedAt": "2026-09-30T00:00:00Z",
          "additions": 1, "deletions": 1, "changedFiles": 1,
          "headRefName": "feature/closed", "baseRefName": "main",
          "repository": { "nameWithOwner": "acme/web" }
        }
      ]
    }
  }
}
"""
