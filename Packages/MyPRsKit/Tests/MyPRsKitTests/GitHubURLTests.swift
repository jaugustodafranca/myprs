import Foundation
import Testing
@testable import MyPRsKit

struct GitHubURLTests {
    @Test func trustsHttpsGitHubPullRequest() {
        #expect(GitHubURL.isTrusted(URL(string: "https://github.com/octo/repo/pull/1")!))
    }

    @Test func trustsHostCaseInsensitively() {
        #expect(GitHubURL.isTrusted(URL(string: "HTTPS://GitHub.com/octo/repo/pull/1")!))
    }

    @Test(arguments: [
        "http://github.com/octo/repo/pull/1",
        "https://evil.com/octo/repo/pull/1",
        "https://github.com.evil.com/pull/1",
        "https://evilgithub.com/pull/1",
        "https://sub.github.com/pull/1",
        "file:///etc/passwd",
        "myprs://callback",
        "javascript:alert(1)",
    ])
    func rejectsOtherURLs(_ string: String) {
        #expect(!GitHubURL.isTrusted(URL(string: string)!))
    }
}
