import Foundation
import Security

/// Read access to the stored Claude API key (lets tests inject a fake provider).
protocol APIKeyProviding {
    func readAPIKey() -> String?
}

/// Stores the Claude API key in the iOS Keychain. The key is never written to
/// UserDefaults, plists, or source control.
struct KeychainHelper: APIKeyProviding {

    private let service = "com.renanbambam.studylens"
    private let account = "claude-api-key"

    func saveAPIKey(_ key: String) throws {
        guard let data = key.data(using: .utf8) else {
            throw StudyLensError.keychainFailure(status: errSecParam)
        }
        // Upsert: Keychain has no insert-or-update, so delete then add.
        SecItemDelete(baseQuery() as CFDictionary)

        var query = baseQuery()
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw StudyLensError.keychainFailure(status: status)
        }
    }

    func readAPIKey() -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func deleteAPIKey() {
        SecItemDelete(baseQuery() as CFDictionary)
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
