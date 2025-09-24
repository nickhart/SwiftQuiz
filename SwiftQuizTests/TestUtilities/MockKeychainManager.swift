import Foundation
@testable import SwiftQuiz

@MainActor
class MockKeychainManager: KeychainProvider {
    private var storage: [String: Data] = [:]

    func store(key: String, service: String, data: Data) throws {
        let storageKey = "\(service).\(key)"
        self.storage[storageKey] = data
    }

    func update(key: String, service: String, data: Data) throws {
        let storageKey = "\(service).\(key)"
        guard self.storage[storageKey] != nil else {
            throw KeychainManager.KeychainError.itemNotFound
        }
        self.storage[storageKey] = data
    }

    func retrieve(key: String, service: String) throws -> Data {
        let storageKey = "\(service).\(key)"
        guard let data = storage[storageKey] else {
            throw KeychainManager.KeychainError.itemNotFound
        }
        return data
    }

    func delete(key: String, service: String) throws {
        let storageKey = "\(service).\(key)"
        self.storage.removeValue(forKey: storageKey)
    }

    func storeOrUpdate(key: String, service: String, data: Data) throws {
        let storageKey = "\(service).\(key)"
        self.storage[storageKey] = data
    }

    func storeAPIKey(_ apiKey: String, for serviceName: String) throws {
        guard let data = apiKey.data(using: .utf8) else {
            throw KeychainManager.KeychainError.invalidData
        }
        try self.storeOrUpdate(key: "api-key", service: serviceName, data: data)
    }

    func retrieveAPIKey(for serviceName: String) throws -> String {
        let data = try retrieve(key: "api-key", service: serviceName)
        guard let apiKey = String(data: data, encoding: .utf8) else {
            throw KeychainManager.KeychainError.invalidData
        }
        return apiKey
    }

    func deleteAPIKey(for serviceName: String) throws {
        try self.delete(key: "api-key", service: serviceName)
    }

    // Test helper methods
    func clear() {
        self.storage.removeAll()
    }

    func hasKey(key: String, service: String) -> Bool {
        let storageKey = "\(service).\(key)"
        return self.storage[storageKey] != nil
    }
}
