import AppIntents
import AppKit

struct CopyLinkIntent: AppIntent {
    static let title: LocalizedStringResource = "Copy PR link"

    @Parameter(title: "URL") var url: String

    init() {}

    init(url: String) {
        self.url = url
    }

    func perform() async throws -> some IntentResult {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url, forType: .string)
        return .result()
    }
}
