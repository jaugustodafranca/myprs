import SwiftUI

/// The MyPRs pull request mark (see assets/logo-mark.svg), without the logo's status dots.
/// Drawn as a filled outline so it scales crisply and can be used as a view, a mask or a CGPath.
struct BrandGlyph: Shape {
    /// Stroke width as a fraction of the glyph size. The logo uses 46 of 480.
    var strokeFraction: CGFloat = 46.0 / 480

    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let unit = side / Design.size
        let origin = CGPoint(x: rect.midX - side / 2, y: rect.midY - side / 2)

        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: origin.x + x * unit, y: origin.y + y * unit)
        }

        var centerline = Path()
        // Line joining the two nodes on the left.
        centerline.move(to: point(Design.left, Design.topNodeY + Design.nodeRadius + Design.gap))
        centerline.addLine(to: point(Design.left, Design.bottomNodeY - Design.nodeRadius - Design.gap))
        // Curve from the bottom right node, ending at the arrow tip.
        centerline.move(to: point(Design.right, Design.bottomNodeY - Design.nodeRadius - Design.gap))
        centerline.addLine(to: point(Design.right, Design.curveY + Design.cornerRadius))
        centerline.addQuadCurve(
            to: point(Design.right - Design.cornerRadius, Design.curveY),
            control: point(Design.right, Design.curveY)
        )
        centerline.addLine(to: point(Design.curveEndX, Design.curveY))
        // Arrowhead pointing left.
        centerline.move(to: point(Design.arrowTipX + Design.arrowDepth, Design.curveY - Design.arrowDepth))
        centerline.addLine(to: point(Design.arrowTipX, Design.curveY))
        centerline.addLine(to: point(Design.arrowTipX + Design.arrowDepth, Design.curveY + Design.arrowDepth))
        // Nodes.
        for (x, y) in [(Design.left, Design.topNodeY), (Design.left, Design.bottomNodeY), (Design.right, Design.bottomNodeY)] {
            centerline.addEllipse(in: CGRect(
                x: origin.x + (x - Design.nodeRadius) * unit,
                y: origin.y + (y - Design.nodeRadius) * unit,
                width: Design.nodeRadius * 2 * unit,
                height: Design.nodeRadius * 2 * unit
            ))
        }

        return centerline.strokedPath(StrokeStyle(lineWidth: side * strokeFraction, lineCap: .round, lineJoin: .round))
    }

    /// Proportions in a 480 x 480 box, taken from the logo.
    private enum Design {
        static let size: CGFloat = 480
        static let left: CGFloat = 92
        static let right: CGFloat = 388
        static let topNodeY: CGFloat = 74
        static let bottomNodeY: CGFloat = 406
        static let nodeRadius: CGFloat = 52
        static let gap: CGFloat = 24
        static let curveY: CGFloat = 116
        static let cornerRadius: CGFloat = 110
        static let curveEndX: CGFloat = 198
        static let arrowTipX: CGFloat = 190
        static let arrowDepth: CGFloat = 52
    }
}
