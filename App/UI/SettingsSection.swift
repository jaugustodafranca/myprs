import SwiftUI
import ServiceManagement

struct SettingsSection: View {
    @Bindable var monitor: PullRequestMonitor
    let updater: Updater
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(spacing: 0) {
            row {
                Text("Refresh every")
                Spacer()
                Picker("Refresh every", selection: $monitor.refreshInterval) {
                    ForEach(PullRequestMonitor.intervalOptions, id: \.self) { interval in
                        Text("\(Int(interval / 60)) min").tag(interval)
                    }
                }
                .labelsHidden()
                .fixedSize()
            }
            Divider()
            row {
                Text("Launch at login")
                Spacer()
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .onChange(of: launchAtLogin) { _, enabled in setLaunchAtLogin(enabled) }
            }
            Divider()
            row {
                CheckForUpdatesButton(updater: updater)
                Spacer()
                Button("Sign out") { monitor.signOut() }
            }
            Divider()
            row {
                Link("Organization access…", destination: AppConfig.organizationAccessURL)
                Spacer()
            }
            Divider()
            row {
                Text(versionText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(GlassCapsuleButtonStyle())
                    .keyboardShortcut("q")
            }
        }
    }

    private func row<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(content: content)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
    }

    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "MyPRs \(version) (\(build))"
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
