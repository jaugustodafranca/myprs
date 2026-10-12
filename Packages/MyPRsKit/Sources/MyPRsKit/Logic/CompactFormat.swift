import Foundation

public enum CompactFormat {
    public static func count(_ value: Int) -> String {
        guard value >= 1000 else { return String(value) }
        let thousands = Double(value) / 1000
        if thousands >= 100 { return "\(Int(thousands))k" }
        let rounded = (thousands * 10).rounded(.down) / 10
        return rounded == rounded.rounded() ? "\(Int(rounded))k" : String(format: "%.1fk", rounded)
    }

    public static func age(from date: Date, to now: Date = .now) -> String {
        let seconds = max(0, now.timeIntervalSince(date))
        switch seconds {
        case ..<60: return "now"
        case ..<3600: return "\(Int(seconds / 60))m"
        case ..<86_400: return "\(Int(seconds / 3600))h"
        case ..<(86_400 * 7): return "\(Int(seconds / 86_400))d"
        case ..<(86_400 * 365): return "\(Int(seconds / (86_400 * 7)))w"
        default: return "\(Int(seconds / (86_400 * 365)))y"
        }
    }
}
