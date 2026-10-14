import Foundation

/// The user's own review prompt. Without one, the default is used. App-only: it never reaches the widget.
struct ReviewPromptStore {
    static var standard: ReviewPromptStore { ReviewPromptStore(defaults: .standard) }

    private static let key = "reviewPromptTemplate"
    let defaults: UserDefaults

    var customTemplate: String? { defaults.string(forKey: Self.key) }

    var template: String { customTemplate ?? DefaultReviewPrompt.template }

    /// Saving a blank prompt or the default itself goes back to using the default.
    func save(_ template: String) {
        let isDefault = template.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || template == DefaultReviewPrompt.template
        if isDefault {
            reset()
        } else {
            defaults.set(template, forKey: Self.key)
        }
    }

    func reset() {
        defaults.removeObject(forKey: Self.key)
    }
}
