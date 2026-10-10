import SwiftUI
import AppKit

struct MenuBarIcon: View {
    let pullRequests: [PullRequest]

    private var tint: NSColor? {
        if pullRequests.contains(where: { $0.checks == .failing }) { return .systemRed }
        if pullRequests.contains(where: { $0.unansweredThreads > 0 }) { return .systemOrange }
        return nil
    }

    var body: some View {
        Image(nsImage: icon)
    }

    // MenuBarExtra ignores SwiftUI tint, so a colored icon must be a non-template NSImage.
    private var icon: NSImage {
        let symbol = NSImage(systemSymbolName: "arrow.triangle.pull", accessibilityDescription: "MyPRs")!
        guard let tint else {
            symbol.isTemplate = true
            return symbol
        }
        let configured = symbol.withSymbolConfiguration(.init(paletteColors: [tint])) ?? symbol
        configured.isTemplate = false
        return configured
    }
}
