import Foundation
@testable import MyPRs
import Testing

struct LoginCallbackTests {
    @Test func returnsTokenWhenStateMatches() throws {
        let url = URL(string: "myprs://auth?token=gho_abc&state=xyz")!
        #expect(try LoginCallback.token(from: url, expectedState: "xyz") == "gho_abc")
    }

    @Test func acceptsTrailingSlashAfterHost() throws {
        let url = URL(string: "myprs://auth/?token=gho_abc&state=xyz")!
        #expect(try LoginCallback.token(from: url, expectedState: "xyz") == "gho_abc")
    }

    @Test func surfacesErrorWithTrailingSlash() {
        let url = URL(string: "myprs://auth/?error=access_denied&state=xyz")!
        #expect(throws: LoginError.denied("access_denied")) {
            try LoginCallback.token(from: url, expectedState: "xyz")
        }
    }

    @Test func rejectsUnexpectedHost() {
        let url = URL(string: "myprs://other?token=t&state=xyz")!
        #expect(throws: LoginError.invalidCallback) {
            try LoginCallback.token(from: url, expectedState: "xyz")
        }
    }

    @Test func rejectsStateMismatch() {
        let url = URL(string: "myprs://auth?token=gho_abc&state=other")!
        #expect(throws: LoginError.stateMismatch) {
            try LoginCallback.token(from: url, expectedState: "xyz")
        }
    }

    @Test func surfacesErrorFromWorker() {
        let url = URL(string: "myprs://auth?error=access_denied&state=xyz")!
        #expect(throws: LoginError.denied("access_denied")) {
            try LoginCallback.token(from: url, expectedState: "xyz")
        }
    }

    @Test func rejectsMissingToken() {
        let url = URL(string: "myprs://auth?state=xyz")!
        #expect(throws: LoginError.invalidCallback) {
            try LoginCallback.token(from: url, expectedState: "xyz")
        }
    }

    @Test func rejectsForeignScheme() {
        let url = URL(string: "https://evil.example/auth?token=t&state=xyz")!
        #expect(throws: LoginError.invalidCallback) {
            try LoginCallback.token(from: url, expectedState: "xyz")
        }
    }
}
