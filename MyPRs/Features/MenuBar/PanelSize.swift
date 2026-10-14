import CoreGraphics

enum PanelSize {
    static let width: CGFloat = 440
    static let defaultScreenHeight: CGFloat = 640
    static let emptyStateHeight: CGFloat = 150

    private static let screenShare: CGFloat = 0.6
    private static let shortestMaxList: CGFloat = 150

    /// The tallest the list may grow before it scrolls, given the measured height
    /// of everything around it (header, banner, settings).
    static func maxListHeight(screenHeight: CGFloat, chromeHeight: CGFloat) -> CGFloat {
        max(shortestMaxList, screenHeight * screenShare - chromeHeight)
    }
}
