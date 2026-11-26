import MyPRsKit
import SwiftUI

struct RevocationNotice: View {
    let acknowledge: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("GitHub hasn’t confirmed that an earlier token was revoked. You can review and revoke MyPRs access on GitHub.")
                .font(.callout)
            HStack {
                Link("Review access on GitHub", destination: AppConfig.organizationAccessURL)
                Button("Dismiss", action: acknowledge)
            }
            .controlSize(.small)
        }
    }
}
