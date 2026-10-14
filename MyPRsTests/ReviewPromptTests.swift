import Foundation
import MyPRsKit
import Testing
@testable import MyPRs

@Suite struct ReviewPromptTests {
    @Test func replacesKnownPlaceholders() {
        let text = ReviewPromptTemplate.render("{{repo}}#{{number}} {{repo}}", values: ["repo": "a/b", "number": "7"])
        #expect(text == "a/b#7 a/b")
    }

    @Test func leavesUnknownPlaceholdersAsWritten() {
        #expect(ReviewPromptTemplate.render("hi {{nope}} {{ spaced }}", values: ["x": "y"]) == "hi {{nope}} {{ spaced }}")
    }

    @Test func doesNotExpandPlaceholdersInsideValues() {
        #expect(ReviewPromptTemplate.render("{{title}}", values: ["title": "{{url}}", "url": "u"]) == "{{url}}")
    }

    @Test func defaultTemplateUsesOnlyKnownPlaceholders() {
        let rendered = ReviewPromptTemplate.render(DefaultReviewPrompt.template, values: ReviewPromptValues.sample)
        #expect(!rendered.contains("{{"))
        #expect(rendered.hasPrefix("Review this pull request: https://github.com/acme/api/pull/128"))
    }

    @Test func buildsValuesFromAnOpenPullRequest() {
        let values = ReviewPromptValues.of(makePullRequest(
            number: 42, repository: "Acme/api", checksPassed: 6, checksTotal: 6, authorLogin: "mrivera"
        ))
        #expect(values["repo"] == "Acme/api")
        #expect(values["number"] == "42")
        #expect(values["author"] == "mrivera")
        #expect(values["checks"] == "passing 6/6")
    }

    @Test func unknownAuthorFallsBack() {
        #expect(ReviewPromptValues.of(makePullRequest(authorLogin: nil))["author"] == "unknown")
    }

    @Test func describesEachCheckState() {
        func text(_ status: CheckStatus) -> String {
            ReviewPromptValues.checksText(makePullRequest(checks: status, checksPassed: 3, checksTotal: 5))
        }
        #expect(text(.passing) == "passing 3/5")
        #expect(text(.failing) == "failing 3/5")
        #expect(text(.running) == "running")
        #expect(text(.none) == "none")
    }

    @Test func closedPullRequestsHaveNoChecksOrAuthor() {
        let closed = ClosedPullRequest(
            id: "c", number: 9, title: "Old", url: URL(string: "https://github.com/a/b/pull/9")!, repository: "a/b",
            headBranch: "h", baseBranch: "main", state: .merged, endedAt: .now, additions: 1, deletions: 2, changedFiles: 3
        )
        let values = ReviewPromptValues.of(closed)
        #expect(values["checks"] == "n/a")
        #expect(values["author"] == "unknown")
        #expect(values["files"] == "3")
    }

    @Test func storeFallsBackToTheDefault() {
        let store = ReviewPromptStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        #expect(store.template == DefaultReviewPrompt.template)
        store.save("custom {{url}}")
        #expect(store.template == "custom {{url}}")
        store.save(DefaultReviewPrompt.template)
        #expect(store.customTemplate == nil)
        store.save("custom")
        store.save("   ")
        #expect(store.customTemplate == nil)
    }
}
