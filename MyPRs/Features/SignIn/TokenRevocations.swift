import Foundation

@MainActor
@Observable
final class TokenRevocations {
    private static let key = "unconfirmedTokenRevocations"
    private let defaults: UserDefaults
    private var pending: Set<String>
    private var inFlight: Set<String> = []

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        pending = Set(defaults.stringArray(forKey: Self.key) ?? [])
    }

    var needsReview: Bool { !pending.isSubset(of: inFlight) }

    @discardableResult
    func start(token: String, worker: AuthWorker) -> Task<Void, Never> {
        let id = UUID().uuidString
        pending.insert(id)
        inFlight.insert(id)
        persist()
        return Task {
            if await worker.revoke(token) {
                pending.remove(id)
                persist()
            }
            inFlight.remove(id)
        }
    }

    func acknowledge() {
        pending.formIntersection(inFlight)
        persist()
    }

    private func persist() {
        // Only attempt IDs survive a quit while the remote revocation is in flight.
        defaults.set(Array(pending), forKey: Self.key)
    }
}
