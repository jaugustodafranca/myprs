import MyPRsKit
import SwiftUI

struct AccountSettingsTab: View {
    let monitor: PullRequestMonitor

    var body: some View {
        Form {
            Section {
                if monitor.isSignedIn {
                    LabeledContent("Signed in as", value: monitor.snapshot?.login ?? "…")
                    LabeledContent("Organization access") {
                        Link("Manage on GitHub…", destination: AppConfig.organizationAccessURL)
                    }
                } else {
                    LabeledContent("GitHub", value: "Not signed in")
                }
            } footer: {
                Text("Organizations that restrict OAuth apps must approve MyPRs before their pull requests show up.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section {
                HStack {
                    Spacer()
                    if monitor.isSignedIn {
                        Button("Sign Out") { monitor.signOut() }
                    } else {
                        Button("Sign in with GitHub") { Task { await monitor.signIn() } }
                            .disabled(monitor.isSigningIn)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(height: 250)
    }
}
