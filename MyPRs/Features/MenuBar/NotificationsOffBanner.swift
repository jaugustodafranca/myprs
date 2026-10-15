import SwiftUI

/// Shown above the lists while macOS is not delivering MyPRs notifications.
struct NotificationsOffBanner: View {
    let permission: NotificationPermission
    let turnOn: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "bell.slash.fill").foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text(permission.bannerTitle).font(.callout.weight(.medium))
                Text("You won't hear about failing CI, new comments or new PRs to review.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button(permission.bannerAction, action: turnOn)
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
