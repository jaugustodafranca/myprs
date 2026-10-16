import SwiftUI

/// A scroll view that is as tall as its content, up to `maxHeight`, then scrolls.
/// Starts at `maxHeight` so a lazy stack has room to lay out before it is measured.
struct FittingScrollView<Content: View>: View {
    let maxHeight: CGFloat
    @ViewBuilder let content: Content
    /// Keeps content inset equally while leaving room beside the native scroller.
    private static var contentInset: CGFloat { 6 }
    @State private var contentHeight: CGFloat?

    var body: some View {
        ScrollView {
            content
                .padding(.horizontal, Self.contentInset)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
        }
        .contentMargins(.vertical, 6, for: .scrollIndicators)
        .frame(height: min(contentHeight ?? maxHeight, maxHeight))
        .animation(.easeOut(duration: 0.15), value: contentHeight)
    }
}
