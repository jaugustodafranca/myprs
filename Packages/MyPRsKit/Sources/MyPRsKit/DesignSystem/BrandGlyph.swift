import SwiftUI

/// The MyPRs pull request mark (see assets/logo-mark.svg), without the logo's status dots.
/// Drawn as a filled outline so it scales crisply and can be used as a view, a mask or a CGPath.
public struct BrandGlyph: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let unit = side / Design.size
        let origin = CGPoint(x: rect.midX - side / 2, y: rect.midY - side / 2)

        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: origin.x + x * unit, y: origin.y + y * unit)
        }

        func circle(centeredAt x: CGFloat, _ y: CGFloat) -> CGRect {
            let radius = Design.nodeRadius
            let diameter = radius * 2 * unit
            return CGRect(origin: point(x - radius, y - radius), size: CGSize(width: diameter, height: diameter))
        }

        let lineStartY = Design.topNodeY + Design.nodeRadius + Design.gap
        let lineEndY = Design.bottomNodeY - Design.nodeRadius - Design.gap

        var centerline = Path()
        // Line joining the two nodes on the left.
        centerline.move(to: point(Design.left, lineStartY))
        centerline.addLine(to: point(Design.left, lineEndY))
        // From the bottom right node up, round the corner, then left towards the arrowhead.
        centerline.move(to: point(Design.right, lineEndY))
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
        centerline.addEllipse(in: circle(centeredAt: Design.left, Design.topNodeY))
        centerline.addEllipse(in: circle(centeredAt: Design.left, Design.bottomNodeY))
        centerline.addEllipse(in: circle(centeredAt: Design.right, Design.bottomNodeY))

        let stroke = StrokeStyle(lineWidth: Design.strokeWidth * unit, lineCap: .round, lineJoin: .round)
        return centerline.strokedPath(stroke)
    }

    /// Proportions in a 480 x 480 box, taken from the logo.
    private enum Design {
        static let size: CGFloat = 480
        static let strokeWidth: CGFloat = 46
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
