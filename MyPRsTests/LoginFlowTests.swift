import Foundation
@testable import MyPRs
import Testing

@MainActor
struct LoginFlowTests {
    @Test func opensAuthorizeURLWithPKCEChallenge() async throws {
        let (flow, _, authorizeURL) = await startSignIn()
        defer { flow.cancel() }

        #expect(query(authorizeURL, "code_challenge_method") == "S256")
        #expect(query(authorizeURL, "code_challenge")?.count == 43)
        #expect(query(authorizeURL, "scope") == "repo read:org")
        #expect(query(authorizeURL, "state")?.isEmpty == false)
    }

    @Test func ignoresForeignURLsAndKeepsWaiting() async throws {
        let (flow, signIn, authorizeURL) = await startSignIn()
        let state = try #require(query(authorizeURL, "state"))

        flow.handle(URL(string: "myprs://other?error=access_denied&state=\(state)")!)
        flow.handle(URL(string: "myprs://auth?error=access_denied&state=wrong")!)
        flow.handle(URL(string: "myprs://auth?error=access_denied")!)
        flow.cancel()

        await #expect(throws: CancellationError.self) { try await signIn.value }
    }

    @Test func completesWithMatchingCallback() async throws {
        let (flow, signIn, authorizeURL) = await startSignIn()
        let state = try #require(query(authorizeURL, "state"))

        flow.handle(URL(string: "myprs://auth?error=access_denied&state=\(state)")!)

        await #expect(throws: LoginError.denied("access_denied")) { try await signIn.value }
    }

    private func startSignIn() async -> (LoginFlow, Task<String, Error>, URL) {
        var opened: URL?
        let flow = LoginFlow(openURL: { opened = $0 })
        let signIn = Task { try await flow.signIn() }
        while opened == nil { await Task.yield() }
        return (flow, signIn, opened!)
    }

    private func query(_ url: URL, _ name: String) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == name }?.value
    }
}
