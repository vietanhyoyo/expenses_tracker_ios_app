import Foundation
import Security

struct AuthTokens: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
}

protocol TokenStore: AnyObject {
    func load() throws -> AuthTokens?
    func save(_ tokens: AuthTokens) throws
    func clear() throws
}

enum TokenStoreError: Error {
    case unexpectedStatus(OSStatus)
}

final class KeychainTokenStore: TokenStore {
    private let service = "com.local.ExpenseTracker.auth"
    private let account = "session"
    private let fallbackKey = "com.local.ExpenseTracker.auth.session"

    func load() throws -> AuthTokens? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return fallbackTokens() }
        if status == errSecMissingEntitlement {
#if targetEnvironment(simulator)
            return fallbackTokens()
#else
            throw TokenStoreError.unexpectedStatus(status)
#endif
        }
        guard status == errSecSuccess else {
            throw TokenStoreError.unexpectedStatus(status)
        }
        guard let data = result as? Data else { return nil }
        return try JSONDecoder().decode(AuthTokens.self, from: data)
    }

    func save(_ tokens: AuthTokens) throws {
        let data = try JSONEncoder().encode(tokens)
        let attributes = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(
            baseQuery as CFDictionary,
            attributes as CFDictionary
        )

        if updateStatus == errSecItemNotFound {
            var query = baseQuery
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            if addStatus == errSecMissingEntitlement {
#if targetEnvironment(simulator)
                saveFallback(tokens)
                return
#else
                throw TokenStoreError.unexpectedStatus(addStatus)
#endif
            }
            guard addStatus == errSecSuccess else {
                throw TokenStoreError.unexpectedStatus(addStatus)
            }
        } else if updateStatus == errSecMissingEntitlement {
#if targetEnvironment(simulator)
            saveFallback(tokens)
            return
#else
            throw TokenStoreError.unexpectedStatus(updateStatus)
#endif
        } else if updateStatus != errSecSuccess {
            throw TokenStoreError.unexpectedStatus(updateStatus)
        }
    }

    func clear() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        if status == errSecMissingEntitlement {
#if targetEnvironment(simulator)
            UserDefaults.standard.removeObject(forKey: fallbackKey)
            return
#else
            throw TokenStoreError.unexpectedStatus(status)
#endif
        }
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw TokenStoreError.unexpectedStatus(status)
        }
        UserDefaults.standard.removeObject(forKey: fallbackKey)
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private func fallbackTokens() -> AuthTokens? {
#if targetEnvironment(simulator)
        guard let data = UserDefaults.standard.data(forKey: fallbackKey) else { return nil }
        return try? JSONDecoder().decode(AuthTokens.self, from: data)
#else
        return nil
#endif
    }

    private func saveFallback(_ tokens: AuthTokens) {
#if targetEnvironment(simulator)
        guard let data = try? JSONEncoder().encode(tokens) else { return }
        UserDefaults.standard.set(data, forKey: fallbackKey)
#endif
    }
}
