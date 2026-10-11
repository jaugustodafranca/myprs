import CoreGraphics

enum PanelSize {
    static let width: CGFloat = 440
    static let defaultScreenHeight: CGFloat = 640

    private static let totalHeight: CGFloat = 560
    private static let screenShare: CGFloat = 0.75
    private static let headerHeight: CGFloat = 69
    private static let settingsHeight: CGFloat = 200
    private static let shortestList: CGFloat = 150

    static func listHeights(screenHeight: CGFloat, showsSettings: Bool) -> ClosedRange<CGFloat> {
        let chrome = headerHeight + (showsSettings ? settingsHeight : 0)
        let tallest = max(shortestList, screenHeight * screenShare - chrome)
        let shortest = min(totalHeight - chrome, tallest)
        return shortest...tallest
    }
}
