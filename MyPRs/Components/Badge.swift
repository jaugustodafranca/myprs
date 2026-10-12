import SwiftUI

struct Badge: View {
    let text: String
    var symbol: String?
    var color: Color = .secondary

    init(text: String, symbol: String? = nil, color: Color = .secondary) {
        self.text = text
        self.symbol = symbol
        self.color = color
    }

    var body: some View {
        HStack(spacing: 3) {
            if let symbol { Image(systemName: symbol).imageScale(.small) }
            Text(text)
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.14), in: Capsule())
        .fixedSize()
    }
}
