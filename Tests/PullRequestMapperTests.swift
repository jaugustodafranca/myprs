import Foundation
import Testing

@Suite struct PullRequestMapperTests {
    private let pullRequests: [PullRequest]

    init() throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(GitHubResponse.self, from: Data(fixture.utf8))
        pullRequests = PullRequestMapper.pullRequests(from: try #require(response.data))
    }

    @Test func skipsNodesThatAreNotPullRequests() {
        #expect(pullRequests.map(\.number) == [1, 2, 3, 4, 5])
    }

    @Test func mapsBasicFields() {
        let first = pullRequests[0]
        #expect(first.id == "PR_1")
        #expect(first.title == "Passing and approved")
        #expect(first.url == URL(string: "https://github.com/acme/web/pull/1"))
        #expect(first.repository == "acme/web")
        #expect(first.updatedAt == Date(timeIntervalSince1970: 1_790_755_200))
    }

    @Test func mapsEachCheckState() {
        #expect(pullRequests.map(\.checks) == [.passing, .failing, .running, .none, .failing])
    }

    @Test func mapsEachReviewDecision() {
        #expect(pullRequests.map(\.review) == [.approved, .changesRequested, .waiting, .waiting, .waiting])
    }

    @Test func marksDrafts() {
        #expect(pullRequests.map(\.isDraft) == [false, false, true, false, false])
    }

    @Test func countsOnlyUnresolvedThreadsNotAnsweredByViewer() {
        #expect(pullRequests.map(\.unansweredThreads) == [0, 1, 0, 0, 1])
    }
}

private let fixture = #"""
{
  "data": {
    "viewer": { "login": "me" },
    "search": {
      "nodes": [
        {
          "id": "PR_1", "number": 1, "title": "Passing and approved",
          "url": "https://github.com/acme/web/pull/1", "isDraft": false,
          "updatedAt": "2026-09-30T08:00:00Z", "reviewDecision": "APPROVED",
          "repository": { "nameWithOwner": "acme/web" },
          "commits": { "nodes": [ { "commit": { "statusCheckRollup": { "state": "SUCCESS" } } } ] },
          "reviewThreads": { "nodes": [] }
        },
        {
          "id": "PR_2", "number": 2, "title": "Failing with reviewer thread",
          "url": "https://github.com/acme/web/pull/2", "isDraft": false,
          "updatedAt": "2026-09-30T08:00:00Z", "reviewDecision": "CHANGES_REQUESTED",
          "repository": { "nameWithOwner": "acme/web" },
          "commits": { "nodes": [ { "commit": { "statusCheckRollup": { "state": "FAILURE" } } } ] },
          "reviewThreads": { "nodes": [
            { "isResolved": false, "comments": { "nodes": [ { "author": { "login": "reviewer" } } ] } },
            { "isResolved": false, "comments": { "nodes": [ { "author": { "login": "me" } } ] } },
            { "isResolved": true, "comments": { "nodes": [ { "author": { "login": "reviewer" } } ] } }
          ] }
        },
        {},
        {
          "id": "PR_3", "number": 3, "title": "Draft still running",
          "url": "https://github.com/acme/api/pull/3", "isDraft": true,
          "updatedAt": "2026-09-30T08:00:00Z", "reviewDecision": "REVIEW_REQUIRED",
          "repository": { "nameWithOwner": "acme/api" },
          "commits": { "nodes": [ { "commit": { "statusCheckRollup": { "state": "PENDING" } } } ] },
          "reviewThreads": { "nodes": [] }
        },
        {
          "id": "PR_4", "number": 4, "title": "No checks",
          "url": "https://github.com/acme/api/pull/4", "isDraft": false,
          "updatedAt": "2026-09-30T08:00:00Z", "reviewDecision": null,
          "repository": { "nameWithOwner": "acme/api" },
          "commits": { "nodes": [ { "commit": { "statusCheckRollup": null } } ] },
          "reviewThreads": { "nodes": [] }
        },
        {
          "id": "PR_5", "number": 5, "title": "Error and deleted commenter",
          "url": "https://github.com/acme/api/pull/5", "isDraft": false,
          "updatedAt": "2026-09-30T08:00:00Z", "reviewDecision": null,
          "repository": { "nameWithOwner": "acme/api" },
          "commits": { "nodes": [ { "commit": { "statusCheckRollup": { "state": "ERROR" } } } ] },
          "reviewThreads": { "nodes": [
            { "isResolved": false, "comments": { "nodes": [ { "author": null } ] } }
          ] }
        }
      ]
    }
  }
}
"""#
