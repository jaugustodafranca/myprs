import Foundation

public enum GitHubURL {
    public static func isTrusted(_ url: URL) -> Bool {
        isHTTPS(url, host: "github.com")
    }

    public static func isTrustedAvatar(_ url: URL) -> Bool {
        isHTTPS(url, host: "avatars.githubusercontent.com")
    }

    private static func isHTTPS(_ url: URL, host: String) -> Bool {
        url.scheme?.lowercased() == "https"
            && url.host?.lowercased() == host
            && url.user == nil
            && url.port == nil
    }
}
