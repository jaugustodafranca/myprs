import MyPRsKit
import SwiftUI

/// Adds or edits a search from a GitHub link or a search query, inside the panel.
/// The draft belongs to `PanelNavigation`, so it survives the panel closing.
struct SearchEditorScreen: View {
    let search: SavedSearch?
    @Binding var draft: SavedSearchDraft
    let save: (SavedSearch) -> Void
    let back: () -> Void
    @FocusState private var nameIsFocused: Bool

    var body: some View {
        PanelScreen(title: search == nil ? "Add Search" : "Edit Search", back: back) {
            Button("Save", action: saveAndGoBack)
                .keyboardShortcut(.defaultAction)
                .disabled(!draft.canSave)
        } content: {
            Form {
                Section {
                    TextField("Name", text: $draft.name, prompt: Text("Team reviews"))
                        .focused($nameIsFocused)
                }
                Section {
                    TextField("GitHub link or search", text: $draft.linkOrQuery, prompt: Text("https://github.com/owner/repo/pulls?q=…"), axis: .vertical)
                        .labelsHidden()
                        .lineLimit(3...6)
                } header: {
                    Text("GitHub link or search")
                } footer: {
                    SavedSearchQueryPreview(input: draft.linkOrQuery, query: draft.query)
                }
                Section {
                    Toggle("Notify me about new pull requests", isOn: $draft.notifies)
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
        }
        .onAppear {
            AppActivation.bringToFront()
            nameIsFocused = draft.name.isEmpty
        }
    }

    private func saveAndGoBack() {
        guard let updated = draft.savedSearch(id: search?.id ?? UUID()) else { return }
        save(updated)
        back()
    }
}
