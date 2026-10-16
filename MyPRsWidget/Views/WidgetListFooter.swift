import SwiftUI

struct WidgetListFooter: View {
    let omittedCount: Int
    let updatedAt: Date

    var body: some View {
        HStack(spacing: 8) {
            if omittedCount > 0 {
                Text("+\(omittedCount) more overall")
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Text("Updated \(updatedAt.formatted(date: .omitted, time: .shortened))")
                .foregroundStyle(.tertiary)
        }
        .font(.system(size: 9))
        .lineLimit(1)
    }
}
