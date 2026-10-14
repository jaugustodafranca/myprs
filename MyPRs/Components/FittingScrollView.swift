import SwiftUI

/// A scroll view that is as tall as its content, up to `maxHeight`, then scrolls.
/// Starts at `maxHeight` so a lazy stack has room to lay out before it is measured.
struct FittingScrollView<Content: View>: View {
    let maxHeight: CGFloat
    @ViewBuilder let content: Content
    /// Keeps trailing controls out from under the vertical scroller.
    private static var scrollerClearance: CGFloat { 6 }
    @State private var contentHeight: CGFloat?

    var body: some View {
        ScrollView {
            content
                .padding(.trailing, Self.scrollerClearance)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
        }
        .frame(height: min(contentHeight ?? maxHeight, maxHeight))
        .animation(.easeOut(duration: 0.15), value: contentHeight)
    }
}
