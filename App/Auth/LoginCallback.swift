import Foundation

enum LoginError: Error, Equatable, LocalizedError {
    case invalidCallback
    case stateMismatch
    case denied(String)

    var errorDescription: String? {
        switch self {
        case .invalidCallback: "The sign-in response was not understood."
        case .stateMismatch: "The sign-in response did not match the request. Try again."
        case .denied(let reason): "GitHub sign-in failed: \(reason)"
        }
    }
}

enum LoginCallback {
    static func token(from url: URL, expectedState: String) throws -> String {
        guard
            url.scheme == AppConfig.urlScheme,
            url.host == "auth",
            ["", "/"].contains(url.path),
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        else {
            throw LoginError.invalidCallback
        }
        func value(_ name: String) -> String? {
            items.first { $0.name == name }?.value
        }

        guard value("state") == expectedState else { throw LoginError.stateMismatch }
        if let error = value("error") { throw LoginError.denied(error) }
        guard let token = value("token"), !token.isEmpty else { throw LoginError.invalidCallback }
        return token
    }
}
