import Foundation

enum CheckoutCommand {
    static func forBranch(_ name: String) -> String? {
        guard !name.isEmpty, !name.hasPrefix("-"),
              name.utf8.allSatisfy(safeBytes.contains) else { return nil }
        return "git checkout \(name) --"
    }

    private static let safeBytes = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._/-".utf8)
}
