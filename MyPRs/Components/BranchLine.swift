import SwiftUI

struct BranchLine: View {
    let head: String
    let base: String

    var body: some View {
        HStack(spacing: 4) {
            Text(head)
                .lineLimit(1)
                .truncationMode(.middle)
            Text("→")
            Text(base)
                .lineLimit(1)
                .fixedSize()
        }
        .font(.caption.monospaced())
        .foregroundStyle(.secondary)
    }
}
