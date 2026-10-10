import AppKit

@MainActor
final class LoginFlow {
    static let shared = LoginFlow()

    private var pending: (state: String, continuation: CheckedContinuation<URL, Error>)?

    func signIn() async throws -> String {
        cancel()
        let state = Self.randomState()
        let callbackURL = try await withCheckedThrowingContinuation { continuation in
            pending = (state, continuation)
            NSWorkspace.shared.open(authorizeURL(state: state))
        }
        return try LoginCallback.token(from: callbackURL, expectedState: state)
    }

    func handle(_ url: URL) {
        guard let pending, url.scheme == AppConfig.urlScheme else { return }
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

    private func authorizeURL(state: String) -> URL {
        var components = URLComponents(string: "https://github.com/login/oauth/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: AppConfig.gitHubClientID),
            URLQueryItem(name: "redirect_uri", value: AppConfig.authCallbackURL),
            URLQueryItem(name: "scope", value: "repo read:org"),
            URLQueryItem(name: "state", value: state),
        ]
        return components.url!
    }
}
