import AppKit
import MyPRsKit
import SwiftUI

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
        let text = count > 0 ? NSAttributedString(string: " \(count)", attributes: [.font: NSFont.menuBarFont(ofSize: 0)]) : nil
        let textWidth = text?.size().width ?? 0
        let size = NSSize(width: Self.glyphSize + textWidth + (dotColor == nil ? 0 : 3), height: 18)
        let dotColor = dotColor

        let image = NSImage(size: size, flipped: false) { _ in
            let glyphFrame = CGRect(x: 0, y: (size.height - Self.glyphSize) / 2, width: Self.glyphSize, height: Self.glyphSize)
            Self.drawGlyph(in: glyphFrame, color: dotColor == nil ? .black : .labelColor)
            if let text {
                let origin = NSPoint(x: Self.glyphSize, y: (size.height - text.size().height) / 2)
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

    private static let glyphSize: CGFloat = 16

    private static func drawGlyph(in frame: CGRect, color: NSColor) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        // The shape is laid out top-down, the image context is bottom-up.
        context.saveGState()
        context.translateBy(x: 0, y: frame.minY + frame.maxY)
        context.scaleBy(x: 1, y: -1)
        context.addPath(BrandGlyph().path(in: frame).cgPath)
        context.setFillColor(color.cgColor)
        context.fillPath()
        context.restoreGState()
    }

    private static func drawText(_ text: NSAttributedString, at origin: NSPoint) {
        let colored = NSMutableAttributedString(attributedString: text)
        colored.addAttribute(.foregroundColor, value: NSColor.labelColor, range: NSRange(location: 0, length: colored.length))
        colored.draw(at: origin)
    }
}
