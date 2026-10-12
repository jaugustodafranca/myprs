import MyPRsKit
import SwiftUI

struct DiffBadge: View {
    let additions: Int
    let deletions: Int

    init(additions: Int, deletions: Int) {
        self.additions = additions
        self.deletions = deletions
    }

    var body: some View {
        HStack(spacing: 4) {
            Text("+\(CompactFormat.count(additions))").foregroundStyle(.green)
            Text("−\(CompactFormat.count(deletions))").foregroundStyle(.red)
        }
        .font(.caption2.weight(.medium).monospacedDigit())
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.secondary.opacity(0.14), in: Capsule())
        .fixedSize()
    }
}
