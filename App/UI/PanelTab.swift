import Foundation

enum PanelTab: String, CaseIterable, Identifiable {
    case open = "Open"
    case recent = "Recent"

    var id: Self { self }
}
