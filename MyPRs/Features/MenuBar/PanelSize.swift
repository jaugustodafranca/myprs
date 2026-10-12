import CoreGraphics

enum PanelSize {
    static let width: CGFloat = 440
    static let defaultScreenHeight: CGFloat = 640
    static let emptyStateHeight: CGFloat = 150

    private static let screenShare: CGFloat = 0.6
    private static let headerHeight: CGFloat = 69
    private static let settingsHeight: CGFloat = 211
    private static let shortestMaxList: CGFloat = 150

    /// The tallest the list may grow before it scrolls.
    static func maxListHeight(screenHeight: CGFloat, showsSettings: Bool) -> CGFloat {
        let chrome = headerHeight + (showsSettings ? settingsHeight : 0)
        return max(shortestMaxList, screenHeight * screenShare - chrome)
    }
}
