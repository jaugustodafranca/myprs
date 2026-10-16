import AppIntents
import AppKit
import MyPRsKit

struct CopyPromptIntent: AppIntent {
    static let isDiscoverable = false
    static let title: LocalizedStringResource = "Copy AI review prompt"

    @Parameter(title: "Values") var valuesJSON: String

    init() {}

    init(valuesJSON: String) { self.valuesJSON = valuesJSON }

    func perform() async throws -> some IntentResult {
        guard let data = Data(base64Encoded: valuesJSON),
              let values = try? JSONDecoder().decode([String: String].self, from: data) else {
            return .result()
        }
        let rendered = ReviewPromptTemplate.render(ReviewPromptStore.widget.template, values: values)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(rendered, forType: .string)
        return .result()
    }
}
