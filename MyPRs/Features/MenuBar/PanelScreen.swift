import SwiftUI

/// A screen inside the panel: a back button, a title, optional trailing action, and scrolling content
/// that is as tall as it needs to be up to the panel's height cap.
struct PanelScreen<Trailing: View, Content: View>: View {
    let title: String
    let back: () -> Void
    @ViewBuilder let trailing: Trailing
    @ViewBuilder let content: Content
    @State private var headerHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            header
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { headerHeight = $0 }
            Divider()
            FittingScrollView(maxHeight: maxContentHeight) { content }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button(action: back) {
                Label("Back", systemImage: "chevron.left")
            }
            .buttonStyle(.borderless)
            .keyboardShortcut(.cancelAction)
            .help("Back (⌘[ or Esc)")
            Text(title)
                .font(.title3.weight(.semibold))
                .lineLimit(1)
            Spacer()
            trailing
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background { backShortcut }
    }

    /// ⌘[ is the usual "back"; Esc is on the visible button.
    private var backShortcut: some View {
        Button("Back", action: back)
            .keyboardShortcut("[", modifiers: .command)
            .frame(width: 0, height: 0)
            .opacity(0)
            .accessibilityHidden(true)
    }

    private var maxContentHeight: CGFloat {
        let screenHeight = NSScreen.main?.visibleFrame.height ?? PanelSize.defaultScreenHeight
        return PanelSize.maxListHeight(screenHeight: screenHeight, chromeHeight: headerHeight)
    }
}

extension PanelScreen where Trailing == EmptyView {
    init(title: String, back: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.init(title: title, back: back, trailing: { EmptyView() }, content: content)
    }
}
