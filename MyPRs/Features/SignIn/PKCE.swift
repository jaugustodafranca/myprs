import CryptoKit
import Foundation
import Security

/// Proof Key for Code Exchange (RFC 7636): only the app that started the sign-in
/// knows the verifier, so a leaked authorization code is useless to anyone else.
struct PKCE {
    let verifier: String

    var challenge: String { Self.challenge(for: verifier) }

    static func random() -> PKCE {
        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        precondition(status == errSecSuccess, "Secure random bytes unavailable")
        return PKCE(verifier: Data(bytes).base64URLEncoded())
    }

    static func challenge(for verifier: String) -> String {
        Data(SHA256.hash(data: Data(verifier.utf8))).base64URLEncoded()
    }
}

private extension Data {
    func base64URLEncoded() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
