import SwiftUI

struct GlassIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 26, height: 26)
            .glassBackground(in: Circle())
            .opacity(configuration.isPressed ? 0.6 : 1)
            .contentShape(Circle())
    }
}
