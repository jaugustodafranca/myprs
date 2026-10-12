import MyPRsKit
import SwiftUI

struct PanelHeader: View {
    @Binding var tab: PanelTab
    let openBadge: OpenCountBadge?
    let subtitle: String
    let isRefreshing: Bool
    let refresh: () -> Void
    @Binding var showsSettings: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                PanelTabs(selection: $tab, openBadge: openBadge)
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
                    Button { showsSettings.toggle() } label: {
                        Image(systemName: "gearshape").foregroundStyle(showsSettings ? Color.accentColor : .primary)
                    }
                    .help("Settings")
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
