import Foundation
import Security

/// Stores one secret in the user's login keychain, under this app's own service name.
/// Used for the Anthropic API key: never in UserDefaults, never in a settings file on disk.
enum KeychainStore {
    private static let service = "io.github.endlyrics.anthropic-api-key"

    static func read() -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        query.removeValue(forKey: kSecReturnData as String)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Replaces the stored key, or removes it when `key` is empty.
    static func write(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
        SecItemDelete(query as CFDictionary)
        guard !key.isEmpty, let data = key.data(using: .utf8) else { return }
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(add as CFDictionary, nil)
    }
}
