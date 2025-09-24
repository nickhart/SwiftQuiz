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
        #if DEBUG
            let enableCloudSync = false
        #else
            let enableCloudSync = true
        #endif
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrSynchronizable as String: enableCloudSync,
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
        print("🔍 KEYCHAIN: Starting storeOrUpdate for service: \(service)")

        // Strategy 1: Try update first (most efficient if item exists)
        do {
            print("🔍 KEYCHAIN: Attempting update...")
            try self.update(key: key, service: service, data: data)
            print("✅ KEYCHAIN: Update succeeded")
            return
        } catch let error as KeychainError {
            print("⚠️ KEYCHAIN: Update failed with: \(error)")
            if case .itemNotFound = error {
                // Continue to create new entry
            } else {
                // Update failed, delete and recreate
                print("🔍 KEYCHAIN: Deleting after failed update...")
                try? self.delete(key: key, service: service)
            }
        } catch {
            print("⚠️ KEYCHAIN: Update failed with unknown error: \(error)")
            try? self.delete(key: key, service: service)
        }

        // Strategy 2: Try create new entry
        do {
            print("🔍 KEYCHAIN: Attempting store...")
            try self.store(key: key, service: service, data: data)
            print("✅ KEYCHAIN: Store succeeded")
            return
        } catch let error as KeychainError {
            print("⚠️ KEYCHAIN: Store failed with: \(error)")
            if case .duplicateEntry = error {
                print("🔍 KEYCHAIN: Handling duplicate entry...")

                // Check if item actually exists and is retrievable
                do {
                    _ = try self.retrieve(key: key, service: service)
                    print("✅ KEYCHAIN: Item exists and is retrievable - trying update instead")
                    try self.update(key: key, service: service, data: data)
                    print("✅ KEYCHAIN: Update succeeded for existing item")
                    return
                } catch {
                    print("❌ KEYCHAIN: Item not retrievable despite duplicate error: \(error)")
                }

                // Force delete
                print("🔍 KEYCHAIN: Force deleting duplicate...")
                do {
                    try self.delete(key: key, service: service)
                    print("✅ KEYCHAIN: Delete succeeded")
                } catch {
                    print("⚠️ KEYCHAIN: Delete failed: \(error)")
                }

                // Retry store
                print("🔍 KEYCHAIN: Retrying store after delete...")
                try self.store(key: key, service: service, data: data)
                print("✅ KEYCHAIN: Store succeeded after delete")
            } else {
                throw error
            }
        } catch {
            print("⚠️ KEYCHAIN: Store failed with unknown error: \(error)")
            throw error
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

    // MARK: - Debug Utilities

    func debugListAllEntries() {
        print("🔍 KEYCHAIN DEBUG: Listing all keychain entries...")
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let items = result as? [[String: Any]] {
            print("🔍 KEYCHAIN DEBUG: Found \(items.count) total entries")
            let swiftQuizEntries = items.filter { item in
                if let service = item[kSecAttrService as String] as? String {
                    return service.contains("SwiftQuiz")
                }
                return false
            }

            print("🔍 KEYCHAIN DEBUG: Found \(swiftQuizEntries.count) SwiftQuiz entries:")
            for item in swiftQuizEntries {
                if let service = item[kSecAttrService as String] as? String,
                   let account = item[kSecAttrAccount as String] as? String {
                    print("  - Service: \(service), Account: \(account)")
                }
            }
        } else {
            print("🔍 KEYCHAIN DEBUG: Error listing entries: \(status)")
        }
    }

    func nukeAllSwiftQuizEntries() {
        print("💥 NUKING all SwiftQuiz keychain entries...")

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "SwiftQuiz", // This will match all SwiftQuiz.* services
        ]

        let status = SecItemDelete(query as CFDictionary)
        print("💥 Nuke result: \(status)")

        // Also try specific known services
        let services = ["SwiftQuiz.Claude.API", "SwiftQuiz.OpenAI.API"]
        for service in services {
            let specificQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
            ]
            let specificStatus = SecItemDelete(specificQuery as CFDictionary)
            print("💥 Nuked \(service): \(specificStatus)")
        }
    }
}
