import MyPRsKit
import Observation
import SwiftUI

/// Which screen the panel shows, and the search or prompt being edited. It outlives the panel's views, so closing
/// the panel to copy a GitHub link does not lose a half-filled form.
@MainActor @Observable
final class PanelNavigation {
    private(set) var route = PanelRoute.list
    var draft = SavedSearchDraft()
    var promptDraft = ""

    func showList() { go(to: .list) }

    func showSettings() { go(to: .settings) }

    func editSearch(_ search: SavedSearch?) {
        draft = search.map(SavedSearchDraft.init) ?? SavedSearchDraft()
        go(to: .editSearch(search))
    }

    func editPrompt() {
        promptDraft = ReviewPromptStore.standard.template
        go(to: .editPrompt)
    }

    private func go(to destination: PanelRoute) {
        withAnimation(.easeInOut(duration: 0.15)) { route = destination }
    }
}
