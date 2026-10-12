import Foundation

public enum CheckStatus: String, Codable, Sendable {
    case passing, failing, running, none
}
