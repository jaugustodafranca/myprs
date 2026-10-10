import SwiftUI
import WidgetKit

/// The app icon in miniature: the logo's blue gradient with a pull request glyph.
struct AppMark: View {
    var size: CGFloat = 19

    var body: some View {
        Image(systemName: "arrow.triangle.pull")
            .font(.system(size: size * 0.6, weight: .bold))
            .foregroundStyle(.white)
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
