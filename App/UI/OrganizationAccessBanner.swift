import SwiftUI

struct OrganizationAccessBanner: View {
    let access: OrganizationAccess
    let checkAgain: () -> Void
    let signInAgain: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.callout.weight(.medium))
                if let detail { Text(detail).font(.caption).foregroundStyle(.secondary) }
                actions
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.12))
    }

    @ViewBuilder
    private var actions: some View {
        if access.needsReauth {
            Button("Sign in again", action: signInAgain).controlSize(.small)
        } else {
            HStack(spacing: 10) {
                Link(destination: AppConfig.organizationAccessURL) { Text("Request access") }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Button("↻ Check again", action: checkAgain)
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var title: String {
        if access.needsReauth { return "Sign in again to check organization access" }
        let organizations = access.restrictedOrganizations
        if organizations.count == 1 { return "\(organizations[0]) hasn't approved MyPRs" }
        return "\(organizations.count) organizations haven't approved MyPRs"
    }

    private var detail: String? {
        guard !access.needsReauth, access.restrictedOrganizations.count > 1 else { return nil }
        return access.restrictedOrganizations.joined(separator: ", ")
    }
}
