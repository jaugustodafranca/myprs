import Foundation

enum PanelTab: String, CaseIterable, Identifiable {
    case open = "Open"
    case recent = "Recent"
    case review = "Review"

    var id: Self { self }
}
