import Foundation
import Security

// MARK: - Keychain管理器
class KeychainManager {
    static let shared = KeychainManager()

    private init() {}

    private let service = "com.runningapp"

    // MARK: - Token Keys
    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"

    // MARK: - 保存Access Token
    func saveAccessToken(_ token: String) {
        save(token, forKey: accessTokenKey)
    }

    // MARK: - 获取Access Token
    func getAccessToken() -> String? {
        return get(forKey: accessTokenKey)
    }

    // MARK: - 保存Refresh Token
    func saveRefreshToken(_ token: String) {
        save(token, forKey: refreshTokenKey)
    }

    // MARK: - 获取Refresh Token
    func getRefreshToken() -> String? {
        return get(forKey: refreshTokenKey)
    }

    // MARK: - 删除所有Token
    func clearTokens() {
        delete(forKey: accessTokenKey)
        delete(forKey: refreshTokenKey)
    }

    // MARK: - 私有方法 - 保存
    private func save(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }

        // 先删除旧值
        delete(forKey: key)

        // 创建查询
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        // 保存
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Keychain save error: \(status)")
        }
    }

    // MARK: - 私有方法 - 获取
    private func get(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess {
            if let data = dataTypeRef as? Data,
               let value = String(data: data, encoding: .utf8) {
                return value
            }
        }

        return nil
    }

    // MARK: - 私有方法 - 删除
    private func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
