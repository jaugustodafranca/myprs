import SwiftUI
import Testing

@Suite struct BrandGlyphTests {
    @Test func outlineIsNotEmpty() {
        let path = BrandGlyph().path(in: CGRect(x: 0, y: 0, width: 16, height: 16))
        #expect(!path.isEmpty)
    }

    @Test func outlineStaysInsideTheRect() {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 100)
        let bounds = BrandGlyph().path(in: rect).boundingRect
        // The logo's round nodes touch the edge of its 480 box (within one unit), so allow a hair.
        #expect(rect.insetBy(dx: -0.5, dy: -0.5).contains(bounds))
    }

    @Test func outlineIsCenteredInANonSquareRect() {
        let rect = CGRect(x: 0, y: 0, width: 200, height: 100)
        let bounds = BrandGlyph().path(in: rect).boundingRect
        #expect(bounds.width <= 100)
        #expect(abs(bounds.midX - rect.midX) < 1)
        #expect(abs(bounds.midY - rect.midY) < 1)
    }
}
