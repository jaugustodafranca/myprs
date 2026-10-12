import SwiftUI
import WidgetKit

/// The app icon in miniature: the logo's blue gradient with the MyPRs glyph.
public struct AppMark: View {
    var size: CGFloat = 19

    public init(size: CGFloat = 19) {
        self.size = size
    }

    public var body: some View {
        BrandGlyph()
            .fill(.white)
            .padding(size * 0.22)
            .frame(width: size, height: size)
            .background(gradient, in: RoundedRectangle(cornerRadius: size * 0.26, style: .continuous))
            .widgetAccentable()
    }

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0x5B / 255, green: 0x8C / 255, blue: 1), Color(red: 0x3A / 255, green: 0x4F / 255, blue: 0xE0 / 255)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
