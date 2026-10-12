import MyPRsKit
import ServiceManagement
import SwiftUI

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
                    ForEach(RefreshInterval.options, id: \.self) { interval in
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
                Text("Organization access")
                Spacer()
                Link("Manage…", destination: AppConfig.organizationAccessURL)
                    .font(.callout)
            }
            Divider()
            footer
        }
    }

    private var footer: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                CheckForUpdatesButton(updater: updater)
                Button { monitor.signOut() } label: {
                    FooterButtonLabel(title: "Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                }
                Button { NSApplication.shared.terminate(nil) } label: {
                    FooterButtonLabel(title: "Quit", systemImage: "power")
                }
                .keyboardShortcut("q")
            }
            .glassButtonStyle()
            .controlSize(.large)
            Text(versionText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func row<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(content: content)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
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

struct FooterButtonLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .labelStyle(.titleAndIcon)
            .font(.callout)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
    }
}
