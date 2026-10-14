import SwiftUI

struct ReviewRetryRow: View {
    let searchName: String
    let retry: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("Couldn't load \u{201C}\(searchName)\u{201D}.")
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            Button("Retry", action: retry)
                .buttonStyle(.link)
            Spacer(minLength: 0)
        }
        .font(.callout)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }
}
