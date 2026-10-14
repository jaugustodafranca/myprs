import MyPRsKit
import SwiftUI

/// "author · repo#123 · 2d". The repository name shrinks first, so the number, age and author stay readable.
struct PullRequestMetaLine: View {
    let repository: String
    let number: Int
    /// Text after the number, such as "2d" or "merged 3d ago".
    let trailing: String
    var isDraft = false
    var author: (login: String, avatarURL: URL?)?

    var body: some View {
        HStack(spacing: 4) {
            if isDraft {
                Text("Draft ·").fixedSize()
            }
            if let author {
                AuthorLabel(login: author.login, avatarURL: author.avatarURL)
                    .fixedSize()
                Text("·")
            }
            Text(RepositoryName.short(repository))
                .lineLimit(1)
                .truncationMode(.middle)
                .help(repository)
            Text(verbatim: "#\(number) · \(trailing)")
                .lineLimit(1)
                .fixedSize()
                .layoutPriority(1)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
