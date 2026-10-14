import MyPRsKit
import SwiftUI

struct PanelHeader: View {
    @Binding var tab: PanelTab
    let badges: [PanelTab: TabCountBadge]
    let subtitle: String
    let isRefreshing: Bool
    let refresh: () -> Void
    let openSettings: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                PanelTabs(selection: $tab, badges: badges)
                    .padding(.leading, -6)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.leading, 6)
            }
            Spacer()
            GlassContainer {
                HStack(spacing: 6) {
                    Button(action: refresh) { refreshLabel }
                    .help("Refresh now")
                    Button(action: openSettings) { Image(systemName: "gearshape") }
                    .help("Settings (⌘,)")
                }
                .buttonStyle(GlassIconButtonStyle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var refreshLabel: some View {
        if isRefreshing {
            ProgressView().controlSize(.small)
        } else {
            Image(systemName: "arrow.clockwise")
        }
    }
}
