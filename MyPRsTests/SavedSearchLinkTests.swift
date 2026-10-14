@testable import MyPRs
import Testing

@Suite struct SavedSearchLinkTests {
    private let ownerLink = "https://github.com/acme/storefront/pulls?q=is%3Apr+AND+state%3Aopen+AND+%28author%3Aana+OR+author%3Abruno+OR+author%3Acarla+OR+author%3Adiego%29+AND+-author%3A%40me+AND+-reviewed-by%3A%40me"

    @Test func repositoryLinkDecodesTheQueryAndScopesItToTheRepository() {
        #expect(SavedSearchLink.query(from: ownerLink) == "is:pr AND state:open AND (author:ana OR author:bruno OR author:carla OR author:diego) AND -author:@me AND -reviewed-by:@me AND repo:acme/storefront")
    }

    @Test func repositoryLinkKeepsAnExistingRepoOrOrgQualifier() {
        #expect(SavedSearchLink.query(from: "https://github.com/acme/web/pulls?q=is%3Apr+repo%3Aacme%2Fapi") == "is:pr repo:acme/api")
        #expect(SavedSearchLink.query(from: "https://github.com/acme/web/pulls?q=is%3Apr+org%3Aacme") == "is:pr org:acme")
    }

    @Test func globalPullsAndIssuesLinksKeepTheQuery() {
        #expect(SavedSearchLink.query(from: "https://github.com/pulls?q=is%3Aopen+is%3Apr+review-requested%3A%40me") == "is:open is:pr review-requested:@me")
        #expect(SavedSearchLink.query(from: "https://github.com/issues?q=is%3Apr+author%3A%40me") == "is:pr author:@me")
    }

    @Test func addsIsPrWhenMissing() {
        #expect(SavedSearchLink.query(from: "https://github.com/pulls?q=is%3Aopen+author%3Aoctocat") == "is:pr AND is:open author:octocat")
        #expect(SavedSearchLink.query(from: "review-requested:@me") == "is:pr AND review-requested:@me")
    }

    @Test func aTopLevelOrIsGroupedBeforeAddingTerms() {
        #expect(SavedSearchLink.query(from: "author:a OR author:b") == "is:pr AND (author:a OR author:b)")
        #expect(SavedSearchLink.query(from: "https://github.com/acme/web/pulls?q=is%3Apr+author%3Aa+OR+author%3Ab") == "(is:pr author:a OR author:b) AND repo:acme/web")
    }

    @Test func aNegatedRepoQualifierDoesNotRemoveTheLinkScope() {
        #expect(SavedSearchLink.query(from: "https://github.com/acme/web/pulls?q=is%3Apr+-repo%3Aacme%2Fold") == "is:pr -repo:acme/old AND repo:acme/web")
    }

    @Test func plainQueryIsTrimmed() {
        #expect(SavedSearchLink.query(from: "  is:pr is:open team-review-requested:acme/web \n") == "is:pr is:open team-review-requested:acme/web")
    }

    @Test func linkWithoutSchemeIsAccepted() {
        #expect(SavedSearchLink.query(from: "github.com/pulls?q=is%3Apr") == "is:pr")
    }

    @Test(arguments: [
        "",
        "   ",
        "https://github.com/acme/web/pulls",
        "https://github.com/pulls?q=",
        "https://evil.com/pulls?q=is%3Apr",
        "https://github.com/acme/web/blob/main/README.md?q=is%3Apr",
    ])
    func rejectsInputWithoutASearch(_ input: String) {
        #expect(SavedSearchLink.query(from: input) == nil)
    }
}
