import Foundation

enum ReviewPromptTemplate {
    /// The placeholders a template can use, in the order the editor lists them.
    static let placeholders = [
        "url", "title", "repo", "number", "author", "head", "base", "additions", "deletions", "files", "checks",
    ]

    /// Replaces each `{{key}}` with its value. Unknown keys stay as written.
    static func render(_ template: String, values: [String: String]) -> String {
        let placeholderPattern = try! Regex(#"\{\{(\w+)\}\}"#)
        return template.replacing(placeholderPattern) { match in
            let key = match.output[1].substring.map(String.init) ?? ""
            return values[key] ?? String(template[match.range])
        }
    }
}
