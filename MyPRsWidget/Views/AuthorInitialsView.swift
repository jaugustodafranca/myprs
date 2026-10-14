import SwiftUI

/// A small circle with the author's initials. Widgets cannot reliably load remote avatars.
struct AuthorInitialsView: View {
    let login: String

    private var initials: String { String(login.prefix(2)).uppercased() }

    private var color: Color {
        let hue = login.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) % 360 }
        return Color(hue: Double(hue) / 360, saturation: 0.45, brightness: 0.75)
    }

    var body: some View {
        Text(initials)
            .font(.system(size: 6, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 13, height: 13)
            .background(color, in: Circle())
    }
}
