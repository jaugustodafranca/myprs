import MyPRsKit
import SwiftUI

/// Settings inside the panel: General, Review, AI review prompt and Account as sections of one form.
struct SettingsScreen: View {
    @Bindable var monitor: PullRequestMonitor
    let updater: Updater
    let back: () -> Void
    let editSearch: (SavedSearch?) -> Void
    let editPrompt: () -> Void

    var body: some View {
        PanelScreen(title: "Settings", back: back) {
            Form {
                GeneralSection(monitor: monitor, updater: updater)
                ReviewSearchesSection(monitor: monitor, editSearch: editSearch)
                ReviewPromptSection(editPrompt: editPrompt)
                AccountSection(monitor: monitor)
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
        }
    }
}
