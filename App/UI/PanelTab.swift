import SwiftUI

enum PanelTab: String, CaseIterable, Identifiable {
    case open = "Open"
    case recent = "Recent"

    var id: Self { self }
}

struct PanelTabPicker: View {
    @Binding var selection: PanelTab

    var body: some View {
        Picker("Pull requests", selection: $selection) {
            ForEach(PanelTab.allCases) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }
}
