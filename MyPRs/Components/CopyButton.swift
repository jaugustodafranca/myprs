import SwiftUI

struct CopyButton: View {
    let symbol: String
    let help: String
    /// Built when clicked, so rows don't render text nobody copies.
    let text: () -> String
    @State private var didCopy = false

    init(symbol: String, help: String, text: @autoclosure @escaping () -> String) {
        self.symbol = symbol
        self.help = help
        self.text = text
    }

    var body: some View {
        Button {
            Pasteboard.copy(text())
            didCopy = true
            Task {
                try? await Task.sleep(for: .seconds(1.2))
                didCopy = false
            }
        } label: {
            Image(systemName: didCopy ? "checkmark" : symbol)
                .font(.caption)
                .foregroundStyle(didCopy ? Color.green : .secondary)
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(didCopy ? "Copied" : help)
    }
}
