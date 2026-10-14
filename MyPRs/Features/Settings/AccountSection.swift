import MyPRsKit
import SwiftUI

struct AccountSection: View {
    let monitor: PullRequestMonitor

    var body: some View {
        Section {
            if monitor.isSignedIn {
                LabeledContent("Signed in as", value: monitor.snapshot?.login ?? "…")
                LabeledContent("Organization access") {
                    Link("Manage on GitHub…", destination: AppConfig.organizationAccessURL)
                }
            } else {
                LabeledContent("GitHub", value: "Not signed in")
            }
            HStack {
                Spacer()
                if monitor.isSignedIn {
                    Button("Sign Out") { monitor.signOut() }
                } else {
                    Button("Sign in with GitHub") { Task { await monitor.signIn() } }
                        .disabled(monitor.isSigningIn)
                }
            }
        } header: {
            Text("Account")
        } footer: {
            Text("Organizations that restrict OAuth apps must approve MyPRs before their pull requests show up.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
