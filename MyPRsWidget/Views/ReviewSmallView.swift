import MyPRsKit
import SwiftUI

/// The small widget of a saved search: its name and how many pull requests wait for review.
struct ReviewSmallView: View {
    let title: String
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                AppMark()
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 2)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("to review")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .minimumScaleFactor(0.7)
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
