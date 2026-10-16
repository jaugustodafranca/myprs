import Foundation
@testable import MyPRsKit
import Testing

@Suite struct PullRequestGroupingTests {
    @Test func groupsAChainAndOrdersItsItemsByCreationDate() {
        let root = branchPR(id: "root", number: 1, head: "root", base: "main", created: 10)
        let child = branchPR(id: "child", number: 2, head: "child", base: "root", created: 30)
        let grandchild = branchPR(id: "grandchild", number: 3, head: "grandchild", base: "child", created: 20)

        let groups = PullRequestGrouping.groups([child, root, grandchild])

        #expect(groups.count == 1)
        #expect(groups[0].id == "root")
        #expect(groups[0].items.map(\.id) == ["child", "grandchild", "root"])
        #expect(groups[0].parentNumbers == ["child": 1, "grandchild": 2])
        #expect(groups[0].isRelated)
        #expect(groups[0].repository == "acme/storefront")
        #expect(groups[0].baseBranch == "main")
    }

    @Test func groupsForksAndSiblingsButKeepsSameBaseBranchesIndependent() {
        let root = branchPR(id: "root", number: 1, head: "root", base: "main", created: 1)
        let siblingA = branchPR(id: "sibling-a", number: 2, head: "feature-a", base: "root", created: 2)
        let siblingB = branchPR(id: "sibling-b", number: 3, head: "feature-b", base: "root", created: 3, repository: "ACME/Storefront")
        let fork = branchPR(id: "fork", number: 4, head: "fork", base: "root", created: 4, repository: "other/repo")
        let independent = branchPR(id: "independent", number: 5, head: "independent", base: "main", created: 5)

        let groups = PullRequestGrouping.groups([root, siblingA, siblingB, fork, independent])

        #expect(groups.map(\.id) == ["independent", "fork", "root"])
        #expect(groups.first(where: { $0.id == "root" })?.items.map(\.id).sorted() == ["root", "sibling-a", "sibling-b"])
        #expect(groups.first(where: { $0.id == "fork" })?.items.map(\.id) == ["fork"])
    }

    @Test func forkParentUsesItsHeadRepositoryAsTheBranchIdentity() {
        let parent = branchPR(
            id: "parent", number: 1, head: "feature", base: "main", created: 1,
            repository: "acme/storefront", headRepository: "jdoe/storefront-fork"
        )
        let forkChild = branchPR(
            id: "fork-child", number: 2, head: "next", base: "feature", created: 2,
            repository: "jdoe/storefront-fork"
        )
        let baseRepoChild = branchPR(
            id: "base-repo-child", number: 3, head: "other", base: "feature", created: 3,
            repository: "acme/storefront"
        )

        let groups = PullRequestGrouping.groups([parent, forkChild, baseRepoChild])

        #expect(groups.first(where: { $0.id == "parent" })?.items.map(\.id).sorted() == ["fork-child", "parent"])
        #expect(groups.first(where: { $0.id == "base-repo-child" })?.items.count == 1)
    }

    @Test func branchNamesAreCaseSensitiveAndMissingHeadRepositoryCannotParent() {
        let caseSensitiveParent = branchPR(id: "case-parent", number: 1, head: "Feature", base: "main", created: 1)
        let caseSensitiveChild = branchPR(id: "case-child", number: 2, head: "child", base: "feature", created: 2)
        let missingRepositoryParent = branchPR(
            id: "missing-repo-parent", number: 3, head: "orphan", base: "main", created: 3,
            hasHeadRepository: false
        )
        let childOfMissingRepository = branchPR(id: "missing-repo-child", number: 4, head: "child2", base: "orphan", created: 4)

        let groups = PullRequestGrouping.groups([
            caseSensitiveParent, caseSensitiveChild, missingRepositoryParent, childOfMissingRepository,
        ])

        #expect(groups.map(\.id).sorted() == ["case-child", "case-parent", "missing-repo-child", "missing-repo-parent"])
    }

    @Test func emptyIdentityAndSelfEdgesStayIndependent() {
        let emptyHead = branchPR(id: "empty-head", number: 1, head: "", base: "main", created: 1)
        let emptyBase = branchPR(id: "empty-base", number: 2, head: "feature", base: "", created: 2)
        let selfEdge = branchPR(id: "self", number: 3, head: "same", base: "same", created: 3)

        let groups = PullRequestGrouping.groups([emptyHead, emptyBase, selfEdge])

        #expect(groups.count == 3)
        #expect(groups.allSatisfy { !$0.isRelated })
    }

    @Test func leavesMissingIdentityAndAmbiguousParentsUngroupedAndDeduplicatesIDs() {
        let parent = branchPR(id: "parent", number: 1, head: "parent", base: "main", created: 1)
        let child = branchPR(id: "child", number: 2, head: "child", base: "parent", created: 2)
        let missingHead = branchPR(id: "missing", number: 3, head: "", base: "parent", created: 3, repository: "")
        let ambiguousA = branchPR(id: "ambiguous-a", number: 4, head: "duplicate", base: "main", created: 4)
        let ambiguousB = branchPR(id: "ambiguous-b", number: 5, head: "duplicate", base: "main", created: 5, repository: "ACME/Storefront")
        let ambiguousChild = branchPR(id: "ambiguous-child", number: 6, head: "child2", base: "duplicate", created: 6)

        let groups = PullRequestGrouping.groups([parent, child, missingHead, ambiguousA, ambiguousB, ambiguousChild, child])

        #expect(groups.map(\.id).sorted() == ["ambiguous-a", "ambiguous-b", "ambiguous-child", "missing", "parent"])
        #expect(groups.first(where: { $0.id == "parent" })?.items.map(\.id).sorted() == ["child", "parent"])
    }

    @Test func cyclesDoNotCreateGroupsAndGroupOrderingUsesNewestItemThenStableID() {
        let cycleA = branchPR(id: "cycle-a", number: 1, head: "a", base: "b", created: 100)
        let cycleB = branchPR(id: "cycle-b", number: 2, head: "b", base: "a", created: 90)
        let rootZ = branchPR(id: "z-root", number: 3, head: "z", base: "main", created: 50)
        let recentChild = branchPR(id: "z-child", number: 4, head: "zc", base: "z", created: 200)
        let rootA = branchPR(id: "a-root", number: 5, head: "a-root-branch", base: "main", created: 200)
        let cycleDescendant = branchPR(id: "cycle-descendant", number: 6, head: "descendant", base: "a", created: 80)
        let descendantChild = branchPR(id: "descendant-child", number: 7, head: "last", base: "descendant", created: 70)

        let groups = PullRequestGrouping.groups([cycleA, cycleB, rootZ, recentChild, rootA, cycleDescendant, descendantChild])

        #expect(groups.map(\.id) == ["a-root", "z-root", "cycle-a", "cycle-b", "cycle-descendant"])
        #expect(groups.first(where: { $0.id == "cycle-descendant" })?.items.map(\.id).sorted() == ["cycle-descendant", "descendant-child"])
        #expect(groups.first(where: { $0.id == "cycle-a" })?.items.count == 1)
        #expect(groups.first(where: { $0.id == "cycle-b" })?.items.count == 1)
    }

    @Test func equalDatedIndependentGroupsUseStableIDOrderRegardlessOfInputOrder() {
        let zulu = branchPR(id: "zulu", number: 1, head: "z", base: "main", created: 50)
        let alpha = branchPR(id: "alpha", number: 2, head: "a", base: "main", created: 50)

        #expect(PullRequestGrouping.groups([zulu, alpha]).map(\.id) == ["alpha", "zulu"])
        #expect(PullRequestGrouping.groups([alpha, zulu]).map(\.id) == ["alpha", "zulu"])
    }
}

private func branchPR(
    id: String,
    number: Int,
    head: String,
    base: String,
    created: TimeInterval,
    repository: String = "acme/storefront",
    headRepository: String? = nil,
    hasHeadRepository: Bool = true
) -> PullRequest {
    PullRequest(
        id: id,
        number: number,
        title: id,
        url: URL(string: "https://github.com/acme/storefront/pull/\(number)")!,
        repository: repository,
        headRepository: hasHeadRepository ? (headRepository ?? repository) : nil,
        isDraft: false,
        checks: .none,
        review: .waiting,
        unansweredThreads: 0,
        updatedAt: Date(timeIntervalSince1970: created),
        createdAt: Date(timeIntervalSince1970: created),
        additions: 0,
        deletions: 0,
        changedFiles: 0,
        headBranch: head,
        baseBranch: base,
        hasConflicts: false,
        checksPassed: 0,
        checksTotal: 0,
        approvals: 0
    )
}
