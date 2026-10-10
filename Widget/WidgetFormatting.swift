import Foundation

enum WidgetFormatting {
    static func compactCount(_ value: Int) -> String {
        guard value >= 1000 else { return "\(value)" }
        let thousands = Double(value) / 1000
        if thousands >= 10 { return "\(Int(thousands))k" }
        let rounded = (thousands * 10).rounded(.down) / 10
        return rounded == rounded.rounded() ? "\(Int(rounded))k" : "\(rounded)k"
    }

    static func diffText(additions: Int, deletions: Int) -> String {
        "+\(compactCount(additions)) \u{2212}\(compactCount(deletions))"
    }

    static func filesText(_ count: Int) -> String {
        count == 1 ? "1 file" : "\(compactCount(count)) files"
    }
}
