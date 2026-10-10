import AppKit
import AuthenticationServices

@MainActor
final class LoginFlow: NSObject, ASWebAuthenticationPresentationContextProviding {
    private var session: ASWebAuthenticationSession?

    func signIn() async throws -> String {
        let state = UUID().uuidString
        let callbackURL = try await authenticate(at: authorizeURL(state: state))
        return try LoginCallback.token(from: callbackURL, expectedState: state)
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        NSApp.keyWindow ?? NSApp.windows.first ?? ASPresentationAnchor()
    }

    private func authorizeURL(state: String) -> URL {
        var components = URLComponents(string: "https://github.com/login/oauth/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: AppConfig.gitHubClientID),
            URLQueryItem(name: "redirect_uri", value: AppConfig.authCallbackURL),
            URLQueryItem(name: "scope", value: "repo"),
            URLQueryItem(name: "state", value: state),
        ]
        return components.url!
    }

    private func authenticate(at url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: AppConfig.urlScheme
            ) { callbackURL, error in
                if let callbackURL {
                    continuation.resume(returning: callbackURL)
                } else {
                    continuation.resume(throwing: error ?? LoginError.invalidCallback)
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.session = session
            session.start()
        }
    }
}
