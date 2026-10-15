import AppKit
import SwiftUI

enum SnapshotError: Error {
    case missingOutputDirectory
    case pngEncodingFailed(String)
    case heightDidNotSettle
}

/// Draws SwiftUI views in an invisible window and saves them as PNG files.
@MainActor
struct SnapshotWriter {
    let directory: URL

    /// The output directory is the first command line argument.
    static func fromCommandLine() throws -> SnapshotWriter {
        guard CommandLine.arguments.count > 1 else { throw SnapshotError.missingOutputDirectory }
        return SnapshotWriter(directory: URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true))
    }

    /// Writes `<name>-light.png` and `<name>-dark.png`. Without a `height` the image is as tall as its content.
    func write<Content: View>(_ content: Content, named name: String, width: CGFloat, height: CGFloat? = nil) async throws {
        for colorScheme in [ColorScheme.light, .dark] {
            let png = try await render(content, width: width, height: height, colorScheme: colorScheme)
            let suffix = colorScheme == .dark ? "dark" : "light"
            try png.write(to: directory.appendingPathComponent("\(name)-\(suffix).png"))
        }
    }

    private func render<Content: View>(_ content: Content, width: CGFloat, height: CGFloat?, colorScheme: ColorScheme) async throws -> Data {
        let appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
        // The real panel is the key window; without this its controls would draw as inactive (gray).
        let host = NSHostingView(rootView: content
            .frame(width: width, height: height)
            .background(Color(nsColor: .windowBackgroundColor))
            .environment(\.controlActiveState, .key))
        host.appearance = appearance

        let window = NSWindow(contentRect: NSRect(origin: .zero, size: host.fittingSize), styleMask: .borderless, backing: .buffered, defer: false)
        window.appearance = appearance
        window.contentView = host
        window.alphaValue = 0
        window.orderFrontRegardless()

        host.frame.size.height = try await settledHeight(of: host, in: window)
        window.setContentSize(host.frame.size)
        window.layoutIfNeeded()
        return try pngData(of: host)
    }

    /// SwiftUI measures lazy content after the first layout, so the height is read until it stops changing.
    private func settledHeight(of host: NSView, in window: NSWindow) async throws -> CGFloat {
        var height = host.fittingSize.height
        var unchangedReads = 0
        for _ in 0..<50 {
            try await Task.sleep(for: .milliseconds(100))
            window.layoutIfNeeded()
            let latest = host.fittingSize.height
            unchangedReads = latest == height ? unchangedReads + 1 : 0
            height = latest
            window.setContentSize(NSSize(width: host.frame.width, height: height))
            if unchangedReads == 3 { return height }
        }
        throw SnapshotError.heightDidNotSettle
    }

    /// Images have twice as many pixels as points, whatever display runs the preview.
    private func pngData(of view: NSView) throws -> Data {
        let size = view.bounds.size
        let pixelScale: CGFloat = 2
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width * pixelScale),
            pixelsHigh: Int(size.height * pixelScale),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw SnapshotError.pngEncodingFailed("no bitmap for a \(size) view")
        }
        bitmap.size = size
        view.cacheDisplay(in: view.bounds, to: bitmap)
        guard let png = bitmap.representation(using: .png, properties: [:]) else {
            throw SnapshotError.pngEncodingFailed("could not encode the bitmap")
        }
        return png
    }
}
