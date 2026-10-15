import ServiceManagement
import SwiftUI

struct GeneralSection: View {
    @Bindable var monitor: PullRequestMonitor
    let updater: Updater
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Section("General") {
            Picker("Refresh every", selection: $monitor.refreshInterval) {
                ForEach(RefreshInterval.options, id: \.self) { interval in
                    Text("\(Int(interval / 60)) minutes").tag(interval)
                }
            }
            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, enabled in setLaunchAtLogin(enabled) }
            LabeledContent("Notifications") { notificationControls }
            LabeledContent("Updates") { CheckForUpdatesButton(updater: updater) }
            LabeledContent("Version", value: versionText)
            HStack {
                Spacer()
                Button("Quit MyPRs") { NSApplication.shared.terminate(nil) }
            }
        }
    }

    private var notificationControls: some View {
        HStack(spacing: 8) {
            Text(monitor.notificationPermission.settingsLabel)
                .foregroundStyle(.secondary)
            if let action = monitor.notificationPermission.settingsAction {
                Button(action) { Task { await monitor.allowNotifications() } }
                    .controlSize(.small)
            }
        }
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
