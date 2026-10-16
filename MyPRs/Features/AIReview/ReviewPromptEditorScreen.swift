import MyPRsKit
import SwiftUI

/// Edits the AI review prompt inside the panel. The draft belongs to `PanelNavigation`, so it survives
/// the panel closing.
struct ReviewPromptEditorScreen: View {
    @Binding var draft: String
    let save: (String) -> Void
    let back: () -> Void
    @State private var confirmsReset = false

    var body: some View {
        PanelScreen(title: "AI Review Prompt", back: back) {
            Button("Save", action: saveAndGoBack)
                .keyboardShortcut(.defaultAction)
        } content: {
            Form {
                Section {
                    TextEditor(text: $draft)
                        .font(.system(.caption, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .frame(height: 240)
                } footer: {
                    placeholderList
                }
                Section("Preview with a sample pull request") {
                    Text(preview)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Section {
                    InlineConfirmation(
                        isPresented: $confirmsReset,
                        message: "Reset the prompt to the default?",
                        confirmTitle: "Reset",
                        confirm: { draft = DefaultReviewPrompt.template }
                    ) {
                        Button("Reset to Default…") { confirmsReset = true }
                            .disabled(draft == DefaultReviewPrompt.template)
                    }
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
        }
        .onAppear { AppActivation.bringToFront() }
    }

    private var preview: String {
        ReviewPromptTemplate.render(draft, values: ReviewPromptValues.sample)
    }

    private var placeholderList: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Click a placeholder to add it at the end.")
            FlowLayout(spacing: 4) {
                ForEach(ReviewPromptTemplate.placeholders, id: \.self) { name in
                    Button("{{\(name)}}") { draft += "{{\(name)}}" }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                        .font(.caption.monospaced())
                }
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func saveAndGoBack() {
        save(draft)
        back()
    }
}
