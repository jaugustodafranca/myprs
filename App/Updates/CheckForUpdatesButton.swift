import SwiftUI

struct CheckForUpdatesButton: View {
    let updater: Updater

    var body: some View {
        Button { updater.checkForUpdates() } label: {
            FooterButtonLabel(title: "Updates", systemImage: "arrow.down.circle")
        }
        .disabled(!updater.canCheckForUpdates)
    }
}
