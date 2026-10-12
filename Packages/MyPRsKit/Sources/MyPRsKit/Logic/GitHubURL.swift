import Foundation

public enum GitHubURL {
    public static func isTrusted(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "https" && url.host?.lowercased() == "github.com"
    }
}
