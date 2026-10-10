import SwiftUI
import ServiceManagement

struct SettingsSection: View {
    @Bindable var monitor: PullRequestMonitor
    let updater: Updater
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Refresh every", selection: $monitor.refreshInterval) {
                ForEach(PullRequestMonitor.intervalOptions, id: \.self) { interval in
                    Text("\(Int(interval / 60)) min").tag(interval)
                }
            }
            Toggle("Launch at login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, enabled in setLaunchAtLogin(enabled) }
            HStack {
                CheckForUpdatesButton(updater: updater)
                Spacer()
                Button("Sign out") { monitor.signOut() }
            }
        }
        .padding(12)
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
