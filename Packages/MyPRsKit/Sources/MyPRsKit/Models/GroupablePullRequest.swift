import Foundation

public protocol GroupablePullRequest: Identifiable where ID == String {
    var id: String { get }
    var number: Int { get }
    var repository: String { get }
    var headRepository: String? { get }
    var headBranch: String { get }
    var baseBranch: String { get }
    var createdAt: Date { get }
}
