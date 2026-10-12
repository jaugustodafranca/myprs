import Foundation
import Security

struct TokenStoreError: LocalizedError {
    let operation: String
    let status: OSStatus

    var errorDescription: String? {
        "Could not \(operation) your sign-in in the Keychain (error \(status))."
    }
}

/// Uses the legacy login keychain: the data-protection keychain needs a
/// provisioning profile, which Developer ID builds without one cannot load.
struct TokenStore {
    private let service = "com.zaintech.myprs"
    private let account: String

    init(account: String = "github-token") {
        self.account = account
    }

    private var identity: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    func save(_ token: String) throws {
        let data = Data(token.utf8)
        let update = SecItemUpdate(identity as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        switch update {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            try add(data)
        default:
            throw TokenStoreError(operation: "update", status: update)
        }
    }

    func load() -> String? {
        var query = identity
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete() {
        SecItemDelete(identity as CFDictionary)
    }

    private func add(_ data: Data) throws {
        var item = identity
        item[kSecValueData as String] = data
        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else { throw TokenStoreError(operation: "save", status: status) }
    }
}
