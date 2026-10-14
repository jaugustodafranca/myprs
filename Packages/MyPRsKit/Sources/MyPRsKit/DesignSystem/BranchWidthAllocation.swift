import CoreGraphics

/// How a branch line splits its width between the head and base names.
struct BranchWidthAllocation: Equatable {
    /// Smallest share of the available width the head keeps when both names are long.
    static let minimumHeadShare: CGFloat = 0.55

    let head: CGFloat
    let base: CGFloat

    init(headIdeal: CGFloat, baseIdeal: CGFloat, available: CGFloat) {
        let available = max(available, 0)
        if headIdeal + baseIdeal <= available {
            head = headIdeal
            base = baseIdeal
            return
        }
        let headWanted = max(available - baseIdeal, available * Self.minimumHeadShare)
        head = min(headIdeal, headWanted)
        base = min(baseIdeal, available - head)
    }
}
