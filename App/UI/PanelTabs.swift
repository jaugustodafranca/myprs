import SwiftUI

/// The panel title: two tabs that slide a highlight between them.
struct PanelTabs: View {
    @Binding var selection: PanelTab
    let openBadge: OpenCountBadge?
    @Namespace private var highlight

    var body: some View {
        HStack(spacing: 2) {
            ForEach(PanelTab.allCases) { tab in
                PanelTabButton(tab: tab, isSelected: selection == tab, badge: tab == .open ? openBadge : nil, highlight: highlight) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.2)) { selection = tab }
                }
            }
        }
    }
}

private struct PanelTabButton: View {
    let tab: PanelTab
    let isSelected: Bool
    let badge: OpenCountBadge?
    let highlight: Namespace.ID
    let select: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: select) {
            HStack(spacing: 6) {
                Text(tab.rawValue)
                    .font(.title3.weight(.semibold))
                if let badge { CountBadge(badge: badge) }
            }
            .foregroundStyle(isSelected || isHovering ? .primary : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background { if isSelected { selectionHighlight } }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .keyboardShortcut(tab.shortcut, modifiers: .command)
    }

    private var selectionHighlight: some View {
        Capsule()
            .fill(.clear)
            .tabHighlight()
            .matchedGeometryEffect(id: "highlight", in: highlight)
    }
}

private struct CountBadge: View {
    let badge: OpenCountBadge

    var body: some View {
        Text("\(badge.count)")
            .font(.caption2.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(tint)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(tint.opacity(0.18), in: Capsule())
    }

    private var tint: Color {
        switch badge.tone {
        case .failing: .red
        case .toAnswer: .orange
        case .neutral: .secondary
        }
    }
}

private extension PanelTab {
    var shortcut: KeyEquivalent {
        switch self {
        case .open: "1"
        case .recent: "2"
        }
    }
}

private extension View {
    @ViewBuilder
    func tabHighlight() -> some View {
        if #available(macOS 26, *) {
            glassBackground(in: Capsule())
        } else {
            background(.quaternary, in: Capsule())
        }
    }
}
