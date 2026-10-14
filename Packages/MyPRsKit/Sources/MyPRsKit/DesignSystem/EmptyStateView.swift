import SwiftUI
import WidgetKit

/// A glowing symbol with a title and subtitle, used when there is nothing to list.
public struct EmptyStateView: View {
    let symbol: String
    let tint: Color
    let title: String
    var subtitle: String?
    var axis: Axis = .vertical
    var symbolSize: CGFloat = 44

    init(
        symbol: String,
        tint: Color,
        title: String,
        subtitle: String? = nil,
        axis: Axis = .vertical,
        symbolSize: CGFloat = 44
    ) {
        self.symbol = symbol
        self.tint = tint
        self.title = title
        self.subtitle = subtitle
        self.axis = axis
        self.symbolSize = symbolSize
    }

    public var body: some View {
        layout {
            glowingSymbol
            texts
        }
    }

    private var layout: AnyLayout {
        axis == .vertical
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 14))
    }

    private var glowingSymbol: some View {
        Image(systemName: symbol)
            .font(.system(size: symbolSize))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(tint)
            .background {
                Circle()
                    .fill(RadialGradient(colors: [tint.opacity(0.32), .clear], center: .center, startRadius: 0, endRadius: symbolSize * 1.1))
                    .frame(width: symbolSize * 2.4, height: symbolSize * 2.4)
            }
            .widgetAccentable()
    }

    private var texts: some View {
        VStack(alignment: axis == .vertical ? .center : .leading, spacing: 3) {
            Text(title)
                .font(axis == .vertical ? .title3.weight(.semibold) : .headline)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .multilineTextAlignment(axis == .vertical ? .center : .leading)
    }
}

extension EmptyStateView {
    public static func allCaughtUp(axis: Axis = .vertical, symbolSize: CGFloat = 44) -> EmptyStateView {
        EmptyStateView(
            symbol: "checkmark.seal.fill",
            tint: .green,
            title: "All caught up",
            subtitle: "No open pull requests. New ones will show up here.",
            axis: axis,
            symbolSize: symbolSize
        )
    }

    public static func nothingToReview(axis: Axis = .vertical, symbolSize: CGFloat = 44) -> EmptyStateView {
        EmptyStateView(
            symbol: "eyes",
            tint: .blue,
            title: "Nothing to review",
            subtitle: "Pull requests from your saved searches will show up here.",
            axis: axis,
            symbolSize: symbolSize
        )
    }

    public static func signedOut(axis: Axis = .vertical, symbolSize: CGFloat = 44) -> EmptyStateView {
        EmptyStateView(
            symbol: "person.crop.circle.badge.questionmark",
            tint: .gray,
            title: "Sign in to MyPRs",
            subtitle: "Open the menu bar app to connect GitHub.",
            axis: axis,
            symbolSize: symbolSize
        )
    }
}
