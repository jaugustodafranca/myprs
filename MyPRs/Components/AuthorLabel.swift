import MyPRsKit
import SwiftUI

/// A pull request author's avatar and login. The avatar loads only from GitHub's avatar host.
struct AuthorLabel: View {
    let login: String
    let avatarURL: URL?

    var body: some View {
        HStack(spacing: 4) {
            avatar
                .frame(width: 14, height: 14)
                .clipShape(Circle())
            Text(login)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var avatar: some View {
        if let avatarURL, GitHubURL.isTrustedAvatar(avatarURL) {
            AsyncImage(url: avatarURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                placeholder
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Circle().fill(.quaternary)
    }
}
