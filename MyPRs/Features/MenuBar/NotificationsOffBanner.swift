import SwiftUI

/// Shown above the lists while macOS has notifications for MyPRs turned off.
struct NotificationsOffBanner: View {
    let openSystemSettings: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "bell.slash.fill").foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text("Notifications are off").font(.callout.weight(.medium))
                Text("You won't hear about failing CI, new comments or new PRs to review.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Open System Settings", action: openSystemSettings)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.12))
    }
}
