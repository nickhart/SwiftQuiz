import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()

    private init() {}

    enum KeychainError: Error {
        case duplicateEntry
        case unknown(OSStatus)
        case itemNotFound
        case invalidData
    }

    func store(key: String, service: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrSynchronizable as String: true,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        switch status {
        case errSecSuccess:
            break
        case errSecDuplicateItem:
            throw KeychainError.duplicateEntry
        default:
            throw KeychainError.unknown(status)
        }
    }

    func update(key: String, service: String, data: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        switch status {
        case errSecSuccess:
            break
        case errSecItemNotFound:
            throw KeychainError.itemNotFound
        default:
            throw KeychainError.unknown(status)
        }
    }

    func retrieve(key: String, service: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw KeychainError.invalidData
            }
            return data
        case errSecItemNotFound:
            throw KeychainError.itemNotFound
        default:
            throw KeychainError.unknown(status)
        }
    }

    func delete(key: String, service: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        let status = SecItemDelete(query as CFDictionary)

        switch status {
        case errSecSuccess, errSecItemNotFound:
            break
        default:
            throw KeychainError.unknown(status)
        }
    }

    func storeOrUpdate(key: String, service: String, data: Data) throws {
        do {
            try self.store(key: key, service: service, data: data)
        } catch KeychainError.duplicateEntry {
            try self.update(key: key, service: service, data: data)
        }
    }
}

extension KeychainManager {
    func storeAPIKey(_ apiKey: String, for serviceName: String) throws {
        guard let data = apiKey.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        try self.storeOrUpdate(key: "api-key", service: serviceName, data: data)
    }

    func retrieveAPIKey(for serviceName: String) throws -> String {
        let data = try retrieve(key: "api-key", service: serviceName)
        guard let apiKey = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return apiKey
    }

    func deleteAPIKey(for serviceName: String) throws {
        try self.delete(key: "api-key", service: serviceName)
    }
}
