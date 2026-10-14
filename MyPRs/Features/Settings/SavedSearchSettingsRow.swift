import MyPRsKit
import SwiftUI

struct SavedSearchSettingsRow: View {
    let search: SavedSearch
    let canMoveUp: Bool
    let canMoveDown: Bool
    let setNotifies: (Bool) -> Void
    let edit: () -> Void
    let move: (Int) -> Void
    let delete: () -> Void
    @State private var confirmsDelete = false

    var body: some View {
        InlineConfirmation(
            isPresented: $confirmsDelete,
            message: "Delete \(search.name)?",
            confirmTitle: "Delete",
            confirm: delete
        ) {
            row
        }
    }

    private var row: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(search.name)
                    .lineLimit(1)
                Text(search.query)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .help(search.query)
            }
            Spacer(minLength: 8)
            Toggle(isOn: Binding(get: { search.notifies }, set: setNotifies)) {
                Image(systemName: search.notifies ? "bell.fill" : "bell.slash")
            }
            .toggleStyle(.button)
            .help(search.notifies ? "Notifies about new pull requests" : "Doesn't notify")
            .accessibilityLabel("Notify about new pull requests")
            Menu {
                Button("Edit Search…", action: edit)
                Divider()
                Button("Move Up") { move(-1) }.disabled(!canMoveUp)
                Button("Move Down") { move(1) }.disabled(!canMoveDown)
                Divider()
                Button("Delete Search…", role: .destructive) { confirmsDelete = true }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .accessibilityLabel("More actions for \(search.name)")
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2, perform: edit)
    }
}
