// Renders the DMG window background (660x400 points) at 1x and 2x.
// Usage: swift scripts/dmg/make-background.swift scripts/dmg
import AppKit

let windowSize = CGSize(width: 660, height: 400)
let appIconCenter = CGPoint(x: 165, y: 190)
let applicationsCenter = CGPoint(x: 495, y: 190)
let iconHalfWidth: CGFloat = 64
let srgb = CGColorSpace(name: CGColorSpace.sRGB)!

func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

// Points use a top-left origin like Finder; CoreGraphics uses bottom-left.
func flipped(_ point: CGPoint) -> CGPoint {
    CGPoint(x: point.x, y: windowSize.height - point.y)
}

func drawBase(in context: CGContext) {
    context.setFillColor(color(0xF3F4FB).cgColor)
    context.fill(CGRect(origin: .zero, size: windowSize))
}

// Large soft blobs in the logo colors, in the style of a blurred gradient.
func drawBlobs(in context: CGContext) {
    let blobs: [(center: CGPoint, radius: CGFloat, hex: UInt32, alpha: CGFloat)] = [
        (CGPoint(x: 90, y: 80), 320, 0x5B8CFF, 0.30),
        (CGPoint(x: 560, y: 330), 340, 0x3A4FE0, 0.28),
        (CGPoint(x: 540, y: 60), 280, 0xA78BFA, 0.28),
    ]
    for blob in blobs {
        let colors = [color(blob.hex, alpha: blob.alpha).cgColor, color(blob.hex, alpha: 0).cgColor] as CFArray
        let gradient = CGGradient(colorsSpace: srgb, colors: colors, locations: [0, 1])!
        let center = flipped(blob.center)
        context.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: blob.radius, options: [])
    }
}

func drawArrow(in context: CGContext) {
    let start = flipped(CGPoint(x: appIconCenter.x + iconHalfWidth + 24, y: appIconCenter.y))
    let tip = flipped(CGPoint(x: applicationsCenter.x - iconHalfWidth - 24, y: applicationsCenter.y))
    let chevron: CGFloat = 8

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -2), blur: 6, color: color(0x3A4FE0, alpha: 0.55).cgColor)
    context.setStrokeColor(color(0xFFFFFF).cgColor)
    context.setLineWidth(3)
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.move(to: start)
    context.addLine(to: tip)
    context.move(to: CGPoint(x: tip.x - chevron, y: tip.y + chevron))
    context.addLine(to: tip)
    context.addLine(to: CGPoint(x: tip.x - chevron, y: tip.y - chevron))
    context.strokePath()
    context.restoreGState()
}

func drawCaption(_ text: String, centerY: CGFloat) {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 13, weight: .medium),
        .foregroundColor: color(0x4A4F86),
    ]
    let string = NSAttributedString(string: text, attributes: attributes)
    let size = string.size()
    string.draw(at: CGPoint(x: (windowSize.width - size.width) / 2, y: windowSize.height - centerY - size.height / 2))
}

func render(scale: Int, to url: URL) throws {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(windowSize.width) * scale, pixelsHigh: Int(windowSize.height) * scale,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    // Declaring the size in points makes the 2x image 144 dpi, which Finder needs for retina.
    bitmap.size = NSSize(width: windowSize.width, height: windowSize.height)

    let graphics = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.current = graphics
    let context = graphics.cgContext

    drawBase(in: context)
    drawBlobs(in: context)
    drawArrow(in: context)
    drawCaption("Drag to Applications", centerY: 312)

    NSGraphicsContext.current = nil
    try bitmap.representation(using: .png, properties: [:])!.write(to: url)
}

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "scripts/dmg")
try render(scale: 1, to: outputDirectory.appendingPathComponent("background.png"))
try render(scale: 2, to: outputDirectory.appendingPathComponent("background@2x.png"))
print("Wrote background.png and background@2x.png to \(outputDirectory.path)")
