import SwiftUI

/// Replaces its content with a confirmation bar while `isPresented` is true.
/// System dialogs open a separate window, which makes the menu bar panel lose focus and close,
/// so every confirmation in the panel is drawn inline.
struct InlineConfirmation<Content: View>: View {
    @Binding var isPresented: Bool
    let message: String
    let confirmTitle: String
    let confirm: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            if isPresented {
                bar
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .leading)))
            } else {
                content()
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.15), value: isPresented)
    }

    private var bar: some View {
        HStack(spacing: 8) {
            Text(message)
                .font(.callout)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(confirmTitle) {
                isPresented = false
                confirm()
            }
            .tint(.red)
            .accessibilityHint(message)
            Button("Cancel") { isPresented = false }
                .keyboardShortcut(.cancelAction)
        }
        .controlSize(.small)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(message)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.red.opacity(0.25)))
    }
}
