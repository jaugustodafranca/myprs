import MyPRsKit
import SwiftUI

struct ReviewSettingsTab: View {
    let monitor: PullRequestMonitor
    @State private var editing: EditorTarget?

    private var savedSearches: SavedSearches { monitor.savedSearches }

    var body: some View {
        Form {
            Section {
                if savedSearches.searches.isEmpty {
                    Text("No searches. The Review tab stays empty until you add one.")
                        .foregroundStyle(.secondary)
                }
                ForEach(Array(savedSearches.searches.enumerated()), id: \.element.id) { index, search in
                    SavedSearchSettingsRow(
                        search: search,
                        canMoveUp: index > 0,
                        canMoveDown: index < savedSearches.searches.count - 1,
                        setNotifies: { savedSearches.setNotifies($0, for: search.id) },
                        edit: { editing = .edit(search) },
                        move: { savedSearches.move(search.id, by: $0) },
                        delete: { monitor.deleteSearch(search.id) }
                    )
                }
            } header: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Searches shown in the Review tab").font(.headline)
                    Text("Paste a GitHub pull request list link, or write a search. A pull request found by several searches is listed under the first.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 4)
            } footer: {
                HStack {
                    Spacer()
                    Button("Add Search…") { editing = .add }
                }
            }
        }
        .formStyle(.grouped)
        .fixedSize(horizontal: false, vertical: true)
        .sheet(item: $editing) { target in
            SavedSearchEditor(title: target.title, save: { save($0, for: target) }, draft: target.draft)
        }
    }

    private func save(_ draft: SavedSearchDraft, for target: EditorTarget) {
        guard let search = draft.savedSearch(id: target.searchID) else { return }
        Task { await monitor.saveSearch(search) }
    }
}

private enum EditorTarget: Identifiable {
    case add
    case edit(SavedSearch)

    var id: String {
        switch self {
        case .add: "add"
        case .edit(let search): search.id.uuidString
        }
    }

    var title: String {
        switch self {
        case .add: "Add Search"
        case .edit: "Edit Search"
        }
    }

    var draft: SavedSearchDraft {
        switch self {
        case .add: SavedSearchDraft()
        case .edit(let search): SavedSearchDraft(search)
        }
    }

    /// A new search gets a fresh id; an edited one keeps its own.
    var searchID: UUID {
        switch self {
        case .add: UUID()
        case .edit(let search): search.id
        }
    }
}
