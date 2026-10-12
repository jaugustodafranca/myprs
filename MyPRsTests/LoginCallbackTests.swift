import Foundation
@testable import MyPRs
import Testing

struct LoginCallbackTests {
    @Test func returnsCodeWhenStateMatches() throws {
        let url = URL(string: "myprs://auth?code=abc123&state=xyz")!
        #expect(try LoginCallback.code(from: url, expectedState: "xyz") == "abc123")
    }

    @Test func acceptsTrailingSlashAfterHost() throws {
        let url = URL(string: "myprs://auth/?code=abc123&state=xyz")!
        #expect(try LoginCallback.code(from: url, expectedState: "xyz") == "abc123")
    }

    @Test func surfacesErrorWithTrailingSlash() {
        let url = URL(string: "myprs://auth/?error=access_denied&state=xyz")!
        #expect(throws: LoginError.denied("access_denied")) {
            try LoginCallback.code(from: url, expectedState: "xyz")
        }
    }

    @Test func rejectsUnexpectedHost() {
        let url = URL(string: "myprs://other?code=abc&state=xyz")!
        #expect(throws: LoginError.invalidCallback) {
            try LoginCallback.code(from: url, expectedState: "xyz")
        }
    }

    @Test func rejectsStateMismatch() {
        let url = URL(string: "myprs://auth?code=abc&state=other")!
        #expect(throws: LoginError.stateMismatch) {
            try LoginCallback.code(from: url, expectedState: "xyz")
        }
    }

    @Test func surfacesErrorFromWorker() {
        let url = URL(string: "myprs://auth?error=access_denied&state=xyz")!
        #expect(throws: LoginError.denied("access_denied")) {
            try LoginCallback.code(from: url, expectedState: "xyz")
        }
    }

    @Test func rejectsMissingCode() {
        let url = URL(string: "myprs://auth?state=xyz")!
        #expect(throws: LoginError.invalidCallback) {
            try LoginCallback.code(from: url, expectedState: "xyz")
        }
    }

    @Test func ignoresTokenParameter() {
        let url = URL(string: "myprs://auth?token=gho_abc&state=xyz")!
        #expect(throws: LoginError.invalidCallback) {
            try LoginCallback.code(from: url, expectedState: "xyz")
        }
    }

    @Test func rejectsForeignScheme() {
        let url = URL(string: "https://evil.example/auth?code=abc&state=xyz")!
        #expect(throws: LoginError.invalidCallback) {
            try LoginCallback.code(from: url, expectedState: "xyz")
        }
    }
}
