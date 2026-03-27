import Foundation
import Security

/// Lightweight Keychain wrapper for storing sensitive integers and strings.
enum KeychainHelper {
    private static let service = "com.nexus.aiidphoto"

    // MARK: - Integer

    static func readInt(key: String) -> Int? {
        guard let data = readData(key: key),
              let str = String(data: data, encoding: .utf8),
              let val = Int(str) else { return nil }
        return val
    }

    static func saveInt(key: String, value: Int) {
        let data = "\(value)".data(using: .utf8)!
        saveData(key: key, data: data)
    }

    // MARK: - String

    static func readString(key: String) -> String? {
        guard let data = readData(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func saveString(key: String, value: String) {
        saveData(key: key, data: value.data(using: .utf8)!)
    }

    // MARK: - Delete

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Raw Data

    private static func readData(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private static func saveData(key: String, data: Data) {
        // Try update first
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        let attrs: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        let updateStatus = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)
        if updateStatus == errSecItemNotFound {
            // Add new item
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }
}
