import MyPRsKit
import SwiftUI

/// Adds or edits a search from a GitHub link or a search query.
struct SavedSearchEditor: View {
    let title: String
    let save: (SavedSearchDraft) -> Void
    @State var draft: SavedSearchDraft
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.headline)
                .padding([.horizontal, .top], 20)
            Form {
                Section {
                    TextField("Name", text: $draft.name, prompt: Text("Team reviews"))
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
            buttons
        }
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var buttons: some View {
        HStack {
            Spacer()
            Button("Cancel", role: .cancel) { dismiss() }
                .keyboardShortcut(.cancelAction)
            Button("Save") {
                save(draft)
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(!draft.canSave)
        }
        .padding([.horizontal, .bottom], 20)
    }
}
