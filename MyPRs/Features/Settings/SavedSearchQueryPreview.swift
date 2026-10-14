import SwiftUI

/// Shows the search MyPRs will run, or why the input is not usable yet.
struct SavedSearchQueryPreview: View {
    let input: String
    let query: String?

    var body: some View {
        if let query {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                Text(query)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text("Paste the link of a GitHub pull request list (with its filters), or type a search such as review-requested:@me.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                Text("This link has no search. Copy it from a GitHub pull requests page after filtering.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
