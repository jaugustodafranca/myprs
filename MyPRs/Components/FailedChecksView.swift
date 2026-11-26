import SwiftUI

struct FailedChecksView: View {
    let failures: [String]
    static let width: CGFloat = 300

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(failures.count == 1 ? "1 failed check" : "\(failures.count) failed checks")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            Divider()
            FittingScrollView(maxHeight: 180) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(failures.indices, id: \.self) { index in
                        if index > 0 { Divider() }
                        Text(verbatim: failures[index])
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
            }
            .scrollIndicatorsFlash(onAppear: true)
        }
        .frame(width: Self.width)
    }
}
