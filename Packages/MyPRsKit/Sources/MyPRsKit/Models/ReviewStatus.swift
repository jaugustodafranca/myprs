import Foundation

public enum ReviewStatus: String, Codable, Sendable {
    case approved, changesRequested, waiting
}
