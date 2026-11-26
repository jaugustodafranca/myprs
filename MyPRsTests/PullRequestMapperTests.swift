import Foundation
import MyPRsKit
@testable import MyPRs
import Testing

@Suite struct PullRequestMapperTests {
    private let pullRequests: [PullRequest]

    init() throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(GitHubResponse.self, from: Data(fixture.utf8))
        let payload = try #require(response.data)
        pullRequests = payload.search.nodes.compactMap(\.pullRequest).map { node in
            let contexts = node.commits.nodes.last?.commit.statusCheckRollup?.contexts.nodes ?? []
            return PullRequestMapper.pullRequest(from: node, viewerLogin: payload.viewer.login,
                                                checks: CheckSummary(contexts), mergeStateStatus: nil)
        }
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

    @Test func mapsSizeBranchesAndDates() {
        let first = pullRequests[0]
        #expect(first.additions == 10)
        #expect(first.deletions == 2)
        #expect(first.changedFiles == 3)
        #expect(first.headBranch == "feature/one")
        #expect(first.baseBranch == "main")
        #expect(first.createdAt == Date(timeIntervalSince1970: 1_790_668_800))
    }

    @Test func flagsOnlyConflictingPullRequests() {
        #expect(pullRequests.map(\.hasConflicts) == [false, true, false, false, false])
    }

    @Test func countsPassedAndTotalChecksAcrossCheckRunsAndStatusContexts() {
        #expect(pullRequests.map(\.checksPassed) == [4, 1, 0, 0, 0])
        #expect(pullRequests.map(\.checksTotal) == [4, 3, 1, 0, 1])
    }

    @Test func countsOnlyApprovedLatestReviews() {
        #expect(pullRequests.map(\.approvals) == [2, 0, 0, 0, 0])
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
          "updatedAt": "2026-09-30T08:00:00Z", "createdAt": "2026-09-29T08:00:00Z",
          "reviewDecision": "APPROVED",
          "additions": 10, "deletions": 2, "changedFiles": 3,
          "headRefName": "feature/one", "baseRefName": "main", "mergeable": "MERGEABLE",
          "latestReviews": { "nodes": [{ "state": "APPROVED" }, { "state": "COMMENTED" }, { "state": "APPROVED" }] },
          "repository": { "nameWithOwner": "acme/web" },
          "commits": { "nodes": [ { "commit": { "oid":"abc", "statusCheckRollup": { "state": "SUCCESS", "contexts": { "pageInfo":{"hasNextPage":false}, "nodes": [{ "name":"job-SUCCESS", "conclusion": "SUCCESS" }, { "name":"job-NEUTRAL", "conclusion": "NEUTRAL" }, { "name":"job-SKIPPED", "conclusion": "SKIPPED" }, { "context":"status-SUCCESS", "state": "SUCCESS" }] } } } } ] },
          "reviewThreads": { "nodes": [] }
        },
        {
          "id": "PR_2", "number": 2, "title": "Failing with reviewer thread",
          "url": "https://github.com/acme/web/pull/2", "isDraft": false,
          "updatedAt": "2026-09-30T08:00:00Z", "createdAt": "2026-09-29T08:00:00Z",
          "reviewDecision": "CHANGES_REQUESTED",
          "additions": 10, "deletions": 2, "changedFiles": 3,
          "headRefName": "feature/one", "baseRefName": "main", "mergeable": "CONFLICTING",
          "latestReviews": { "nodes": [{ "state": "CHANGES_REQUESTED" }] },
          "repository": { "nameWithOwner": "acme/web" },
          "commits": { "nodes": [ { "commit": { "oid":"abc", "statusCheckRollup": { "state": "FAILURE", "contexts": { "pageInfo":{"hasNextPage":false}, "nodes": [{ "name":"job-SUCCESS", "conclusion": "SUCCESS" }, { "context":"status-FAILURE", "state": "FAILURE" }, { "context":"status-PENDING", "state": "PENDING" }] } } } } ] },
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
          "updatedAt": "2026-09-30T08:00:00Z", "createdAt": "2026-09-29T08:00:00Z",
          "reviewDecision": "REVIEW_REQUIRED",
          "additions": 10, "deletions": 2, "changedFiles": 3,
          "headRefName": "feature/one", "baseRefName": "main", "mergeable": "UNKNOWN",
          "latestReviews": { "nodes": [] },
          "repository": { "nameWithOwner": "acme/api" },
          "commits": { "nodes": [ { "commit": { "oid":"abc", "statusCheckRollup": { "state": "PENDING", "contexts": { "pageInfo":{"hasNextPage":false}, "nodes": [{ "name":"build", "status":"IN_PROGRESS" }] } } } } ] },
          "reviewThreads": { "nodes": [] }
        },
        {
          "id": "PR_4", "number": 4, "title": "No checks",
          "url": "https://github.com/acme/api/pull/4", "isDraft": false,
          "updatedAt": "2026-09-30T08:00:00Z", "createdAt": "2026-09-29T08:00:00Z",
          "reviewDecision": null,
          "additions": 10, "deletions": 2, "changedFiles": 3,
          "headRefName": "feature/one", "baseRefName": "main", "mergeable": "MERGEABLE",
          "latestReviews": { "nodes": [] },
          "repository": { "nameWithOwner": "acme/api" },
          "commits": { "nodes": [ { "commit": { "oid":"abc", "statusCheckRollup": null } } ] },
          "reviewThreads": { "nodes": [] }
        },
        {
          "id": "PR_5", "number": 5, "title": "Error and deleted commenter",
          "url": "https://github.com/acme/api/pull/5", "isDraft": false,
          "updatedAt": "2026-09-30T08:00:00Z", "createdAt": "2026-09-29T08:00:00Z",
          "reviewDecision": null,
          "additions": 10, "deletions": 2, "changedFiles": 3,
          "headRefName": "feature/one", "baseRefName": "main", "mergeable": "MERGEABLE",
          "latestReviews": { "nodes": [] },
          "repository": { "nameWithOwner": "acme/api" },
          "commits": { "nodes": [ { "commit": { "oid":"abc", "statusCheckRollup": { "state": "ERROR", "contexts": { "pageInfo":{"hasNextPage":false}, "nodes": [{ "context":"status-ERROR", "state": "ERROR" }] } } } } ] },
          "reviewThreads": { "nodes": [
            { "isResolved": false, "comments": { "nodes": [ { "author": null } ] } }
          ] }
        }
      ]
    }
  }
}
"""#
