import SwiftUI

struct CopyButton: View {
    let symbol: String
    let help: String
    let text: String
    @State private var didCopy = false

    var body: some View {
        Button {
            Pasteboard.copy(text)
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
