import SwiftUI
import AppKit

struct MenuBarIcon: View {
    let pullRequests: [PullRequest]
    let isSignedIn: Bool

    var body: some View {
        Image(nsImage: icon)
    }

    private var count: Int { isSignedIn ? pullRequests.count : 0 }

    private var dotColor: NSColor? {
        guard isSignedIn else { return nil }
        if pullRequests.contains(where: { $0.checks == .failing }) { return .systemRed }
        if pullRequests.contains(where: { $0.unansweredThreads > 0 }) { return .systemOrange }
        return nil
    }

    // MenuBarExtra ignores SwiftUI colors, so the glyph, number and dot are drawn into one image.
    // Without a dot it stays a template image and adapts to the menu bar on its own.
    private var icon: NSImage {
        let symbol = NSImage(systemSymbolName: "arrow.triangle.pull", accessibilityDescription: "MyPRs")!
            .withSymbolConfiguration(.init(pointSize: 14, weight: .medium))!
        let text = count > 0 ? NSAttributedString(string: " \(count)", attributes: [.font: NSFont.menuBarFont(ofSize: 0)]) : nil
        let textWidth = text?.size().width ?? 0
        let size = NSSize(width: symbol.size.width + textWidth + (dotColor == nil ? 0 : 3), height: 18)
        let dotColor = dotColor

        let image = NSImage(size: size, flipped: false) { _ in
            let symbolOrigin = NSPoint(x: 0, y: (size.height - symbol.size.height) / 2)
            Self.drawTemplate(symbol, at: symbolOrigin, tinted: dotColor != nil)
            if let text {
                let origin = NSPoint(x: symbol.size.width, y: (size.height - text.size().height) / 2)
                if dotColor != nil { Self.drawText(text, at: origin) } else { text.draw(at: origin) }
            }
            if let dotColor {
                dotColor.setFill()
                NSBezierPath(ovalIn: NSRect(x: size.width - 6, y: size.height - 7, width: 6, height: 6)).fill()
            }
            return true
        }
        image.isTemplate = dotColor == nil
        return image
    }

    private static func drawTemplate(_ symbol: NSImage, at origin: NSPoint, tinted: Bool) {
        guard tinted else {
            symbol.draw(at: origin, from: .zero, operation: .sourceOver, fraction: 1)
            return
        }
        let tintedSymbol = symbol.copy() as! NSImage
        tintedSymbol.lockFocus()
        NSColor.labelColor.set()
        NSRect(origin: .zero, size: tintedSymbol.size).fill(using: .sourceAtop)
        tintedSymbol.unlockFocus()
        tintedSymbol.draw(at: origin, from: .zero, operation: .sourceOver, fraction: 1)
    }

    private static func drawText(_ text: NSAttributedString, at origin: NSPoint) {
        let colored = NSMutableAttributedString(attributedString: text)
        colored.addAttribute(.foregroundColor, value: NSColor.labelColor, range: NSRange(location: 0, length: colored.length))
        colored.draw(at: origin)
    }
}
