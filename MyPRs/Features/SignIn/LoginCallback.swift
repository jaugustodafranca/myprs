import Foundation
import MyPRsKit

enum LoginError: Error, Equatable, LocalizedError {
    case invalidCallback
    case stateMismatch
    case denied(String)
    case exchangeFailed

    var errorDescription: String? {
        switch self {
        case .invalidCallback: "The sign-in response was not understood."
        case .stateMismatch: "The sign-in response did not match the request. Try again."
        case .denied(let reason): "GitHub sign-in failed: \(reason)"
        case .exchangeFailed: "Could not finish signing in with GitHub. Try again."
        }
    }
}

enum LoginCallback {
    static func isSignInCallback(_ url: URL) -> Bool {
        url.scheme == AppConfig.urlScheme && url.host == "auth" && ["", "/"].contains(url.path)
    }

    static func state(in url: URL) -> String? {
        value("state", in: url)
    }

    static func code(from url: URL, expectedState: String) throws -> String {
        guard isSignInCallback(url) else { throw LoginError.invalidCallback }
        guard state(in: url) == expectedState else { throw LoginError.stateMismatch }
        if let error = value("error", in: url) { throw LoginError.denied(error) }
        guard let code = value("code", in: url), !code.isEmpty else { throw LoginError.invalidCallback }
        return code
    }

    private static func value(_ name: String, in url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == name }?.value
    }
}
