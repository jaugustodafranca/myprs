import SwiftUI

/// The Settings window (⌘, or the gear in the panel).
struct SettingsView: View {
    let monitor: PullRequestMonitor
    let updater: Updater

    var body: some View {
        TabView {
            GeneralSettingsTab(monitor: monitor, updater: updater)
                .tabItem { Label("General", systemImage: "gearshape") }
            ReviewSettingsTab(monitor: monitor)
                .tabItem { Label("Review", systemImage: "eye") }
            AccountSettingsTab(monitor: monitor)
                .tabItem { Label("Account", systemImage: "person.crop.circle") }
        }
        .frame(width: 520)
    }
}
