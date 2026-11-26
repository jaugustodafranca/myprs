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
        try? read()
    }

    func read() throws -> String? {
        var query = identity
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw TokenStoreError(operation: "read", status: status) }
        guard let data = result as? Data, let token = String(data: data, encoding: .utf8) else {
            throw TokenStoreError(operation: "read", status: errSecDecode)
        }
        return token
    }

    func delete() throws {
        let status = SecItemDelete(identity as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw TokenStoreError(operation: "delete", status: status)
        }
    }

    private func add(_ data: Data) throws {
        var item = identity
        item[kSecValueData as String] = data
        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else { throw TokenStoreError(operation: "save", status: status) }
    }
}
