import AppIntents
import AppKit

struct CopyBranchIntent: AppIntent {
    static let isDiscoverable = false
    static let title: LocalizedStringResource = "Copy PR branch"

    @Parameter(title: "Branch") var branch: String

    init() {}

    init(branch: String) {
        self.branch = branch
    }

    func perform() async throws -> some IntentResult {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(branch, forType: .string)
        return .result()
    }
}
