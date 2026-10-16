import Foundation
import MyPRsKit

/// The values a pull request fills into the review prompt.
public enum ReviewPromptValues {
    public static func of(_ pullRequest: PullRequest) -> [String: String] {
        values(
            url: pullRequest.url, title: pullRequest.title, repository: pullRequest.repository,
            number: pullRequest.number, author: pullRequest.authorLogin,
            head: pullRequest.headBranch, base: pullRequest.baseBranch,
            additions: pullRequest.additions, deletions: pullRequest.deletions, files: pullRequest.changedFiles,
            checks: checksText(pullRequest)
        )
    }

    /// Closed pull requests don't carry CI results or an author.
    public static func of(_ pullRequest: ClosedPullRequest) -> [String: String] {
        values(
            url: pullRequest.url, title: pullRequest.title, repository: pullRequest.repository,
            number: pullRequest.number, author: nil,
            head: pullRequest.headBranch, base: pullRequest.baseBranch,
            additions: pullRequest.additions, deletions: pullRequest.deletions, files: pullRequest.changedFiles,
            checks: "n/a"
        )
    }

    public static let sample = [
        "url": "https://github.com/acme/api/pull/128",
        "title": "Add retry budget to the webhook consumer",
        "repo": "acme/api",
        "number": "128",
        "author": "mrivera",
        "head": "feature/retry-budget",
        "base": "main",
        "additions": "214",
        "deletions": "38",
        "files": "7",
        "checks": "passing 6/6",
    ]

    public static func checksText(_ pullRequest: PullRequest) -> String {
        let counts = "\(pullRequest.checksPassed)/\(pullRequest.checksTotal)"
        switch pullRequest.checks {
        case .passing: return "passing \(counts)"
        case .failing: return "failing \(counts)"
        case .running: return "running"
        case .none: return "none"
        }
    }

    private static func values(
        url: URL, title: String, repository: String, number: Int, author: String?,
        head: String, base: String, additions: Int, deletions: Int, files: Int, checks: String
    ) -> [String: String] {
        [
            "url": url.absoluteString,
            "title": title,
            "repo": repository,
            "number": String(number),
            "author": author ?? "unknown",
            "head": head,
            "base": base,
            "additions": String(additions),
            "deletions": String(deletions),
            "files": String(files),
            "checks": checks,
        ]
    }
}
