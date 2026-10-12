import Foundation

public enum RefreshInterval {
    public static let options: [TimeInterval] = [5, 10, 15, 30, 60].map { $0 * 60 }
    public static let standard: TimeInterval = 30 * 60

    public static func restored(from stored: TimeInterval) -> TimeInterval {
        options.contains(stored) ? stored : standard
    }
}
