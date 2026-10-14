import ServiceManagement
import SwiftUI

struct GeneralSettingsTab: View {
    @Bindable var monitor: PullRequestMonitor
    let updater: Updater
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section {
                Picker("Refresh every", selection: $monitor.refreshInterval) {
                    ForEach(RefreshInterval.options, id: \.self) { interval in
                        Text("\(Int(interval / 60)) minutes").tag(interval)
                    }
                }
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in setLaunchAtLogin(enabled) }
            }
            Section {
                LabeledContent("Version", value: versionText)
                LabeledContent("Updates") { CheckForUpdatesButton(updater: updater) }
            }
            Section {
                HStack {
                    Spacer()
                    Button("Quit MyPRs") { NSApplication.shared.terminate(nil) }
                        .keyboardShortcut("q")
                }
            }
        }
        .formStyle(.grouped)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
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
