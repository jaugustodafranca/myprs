import MyPRsKit
import SwiftUI

struct ReviewPromptSection: View {
    let editPrompt: () -> Void

    var body: some View {
        Section {
            Button(action: editPrompt) {
                HStack {
                    Text("Edit prompt…")
                    Spacer()
                    Text(ReviewPromptStore.standard.customTemplate == nil ? "Default" : "Custom")
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } header: {
            Text("AI review prompt")
        } footer: {
            Text("The sparkles button on a pull request copies this prompt, filled in with its details, to paste into your AI assistant.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
