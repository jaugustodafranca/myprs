import MyPRsKit
import SwiftUI

struct ReviewSearchesSection: View {
    let monitor: PullRequestMonitor
    let editSearch: (SavedSearch?) -> Void

    private var savedSearches: SavedSearches { monitor.savedSearches }

    var body: some View {
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
                    edit: { editSearch(search) },
                    move: { savedSearches.move(search.id, by: $0) },
                    delete: { monitor.deleteSearch(search.id) }
                )
            }
        } header: {
            VStack(alignment: .leading, spacing: 2) {
                Text("Searches shown in the Review tab")
                Text("Paste a GitHub pull request list link, or write a search. A pull request found by several searches is listed under the first.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } footer: {
            HStack {
                if !savedSearches.canAddSearch {
                    Text("Up to \(SavedSearches.maximumCount) searches.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Add Search") { editSearch(nil) }
                    .disabled(!savedSearches.canAddSearch)
            }
        }
    }
}
