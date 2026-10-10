import SwiftUI
import AppKit

struct PullRequestRow: View {
    let pullRequest: PullRequest
    @State private var isHovering = false
    @State private var didCopy = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            StatusDot(pullRequest: pullRequest)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 2) {
                Text(pullRequest.title)
                    .lineLimit(2)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            if isHovering {
                actions
            } else {
                indicators
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isHovering ? Color.primary.opacity(0.08) : .clear, in: RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .onTapGesture(perform: open)
    }

    private var subtitle: String {
        let location = "\(pullRequest.repository)#\(pullRequest.number)"
        return pullRequest.isDraft ? "Draft · \(location)" : location
    }

    private var indicators: some View {
        HStack(spacing: 8) {
            if pullRequest.unansweredThreads > 0 {
                Label("\(pullRequest.unansweredThreads)", systemImage: "bubble.left.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            Image(systemName: reviewSymbol)
                .foregroundStyle(reviewColor)
        }
        .labelStyle(.titleAndIcon)
    }

    private var actions: some View {
        HStack(spacing: 4) {
            Button(action: open) { Image(systemName: "arrow.up.right.square") }
                .help("Open")
            Button(action: copyLink) { Image(systemName: didCopy ? "checkmark" : "link") }
                .help(didCopy ? "Copied" : "Copy link")
        }
        .buttonStyle(.borderless)
    }

    private var reviewSymbol: String {
        switch pullRequest.review {
        case .approved: "checkmark.circle.fill"
        case .changesRequested: "exclamationmark.circle.fill"
        case .waiting: "clock"
        }
    }

    private var reviewColor: Color {
        switch pullRequest.review {
        case .approved: .green
        case .changesRequested: .red
        case .waiting: .secondary
        }
    }

    private func open() {
        NSWorkspace.shared.open(pullRequest.url)
    }

    private func copyLink() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(pullRequest.url.absoluteString, forType: .string)
        didCopy = true
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            didCopy = false
        }
    }
}
