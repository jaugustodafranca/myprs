import AppKit
import MyPRsKit

@MainActor
final class LoginFlow {
    static let shared = LoginFlow()

    private let openURL: @MainActor (URL) -> Void
    private let authWorker: AuthWorker
    private var pending: (state: String, continuation: CheckedContinuation<URL, Error>)?

    init(openURL: @escaping @MainActor (URL) -> Void = { NSWorkspace.shared.open($0) }, authWorker: AuthWorker = AuthWorker()) {
        self.openURL = openURL
        self.authWorker = authWorker
    }

    func signIn() async throws -> String {
        cancel()
        let state = Self.randomState()
        let pkce = PKCE.random()
        let callbackURL = try await withCheckedThrowingContinuation { continuation in
            pending = (state, continuation)
            openURL(authorizeURL(state: state, codeChallenge: pkce.challenge))
        }
        let code = try LoginCallback.code(from: callbackURL, expectedState: state)
        return try await authWorker.exchange(code: code, verifier: pkce.verifier)
    }

    /// Only a sign-in callback carrying the pending state completes the sign-in;
    /// any other URL is ignored so it cannot abort or hijack it.
    func handle(_ url: URL) {
        guard let pending,
              LoginCallback.isSignInCallback(url),
              LoginCallback.state(in: url) == pending.state
        else { return }
        self.pending = nil
        pending.continuation.resume(returning: url)
    }

    func cancel() {
        pending?.continuation.resume(throwing: CancellationError())
        pending = nil
    }

    private static func randomState() -> String {
        var generator = SystemRandomNumberGenerator()
        return (0..<32).map { _ in String(format: "%02x", UInt8.random(in: .min ... .max, using: &generator)) }.joined()
    }

    private func authorizeURL(state: String, codeChallenge: String) -> URL {
        var components = URLComponents(string: "https://github.com/login/oauth/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: AppConfig.gitHubClientID),
            URLQueryItem(name: "redirect_uri", value: AppConfig.authCallbackURL),
            URLQueryItem(name: "scope", value: "repo read:org"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
        ]
        return components.url!
    }
}
