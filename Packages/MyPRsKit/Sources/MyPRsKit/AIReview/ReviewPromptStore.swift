import Foundation

/// The shared review prompt. The app keeps its existing standard defaults key and mirrors it for widgets.
public struct ReviewPromptStore {
    public static var standard: ReviewPromptStore {
        ReviewPromptStore(defaults: .standard, mirrorsAppGroup: true)
    }
    public static var widget: ReviewPromptStore {
        ReviewPromptStore(defaults: AppGroupContainer.sharedDefaults ?? .standard)
    }

    private static let key = "reviewPromptTemplate"
    let defaults: UserDefaults
    private let cacheDefaults: UserDefaults?
    private let mirrorsAppGroup: Bool

    public init(defaults: UserDefaults, cacheDefaults: UserDefaults? = nil, mirrorsAppGroup: Bool = false) {
        self.defaults = defaults
        self.cacheDefaults = cacheDefaults
        self.mirrorsAppGroup = mirrorsAppGroup
    }

    public var customTemplate: String? { defaults.string(forKey: Self.key) }

    public var template: String { customTemplate ?? DefaultReviewPrompt.template }

    /// Saving a blank prompt or the default itself goes back to using the default.
    public func save(_ template: String) {
        let isDefault = template.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || template == DefaultReviewPrompt.template
        if isDefault {
            reset()
        } else {
            defaults.set(template, forKey: Self.key)
            mirrorDefaults?.set(template, forKey: Self.key)
        }
    }

    public func reset() {
        defaults.removeObject(forKey: Self.key)
        mirrorDefaults?.removeObject(forKey: Self.key)
    }

    /// Copies an existing app preference to the widget cache when the app starts.
    public func synchronizeAppGroup() {
        if let customTemplate {
            mirrorDefaults?.set(customTemplate, forKey: Self.key)
        } else {
            mirrorDefaults?.removeObject(forKey: Self.key)
        }
    }

    private var mirrorDefaults: UserDefaults? {
        cacheDefaults ?? (mirrorsAppGroup ? AppGroupContainer.sharedDefaults : nil)
    }
}
