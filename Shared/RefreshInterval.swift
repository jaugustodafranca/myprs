import Foundation

enum RefreshInterval {
    static let options: [TimeInterval] = [5, 10, 15, 30, 60].map { $0 * 60 }
    static let standard: TimeInterval = 30 * 60

    static func restored(from stored: TimeInterval) -> TimeInterval {
        options.contains(stored) ? stored : standard
    }
}
