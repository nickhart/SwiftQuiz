//
//  KeychainService.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/15/25.
//

import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()

    private let serviceName = "com.nickhart.SwiftQuiz"

    private init() {}

    enum KeychainError: Error {
        case duplicateEntry
        case unknown(OSStatus)
        case itemNotFound
        case invalidData
    }

    /// Store a value in the Keychain
    func store(_ value: String, for key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        // First, try to delete any existing item
        try? self.delete(key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }

        print("🔐 Keychain: Stored value for key '\(key)'")
    }

    /// Retrieve a value from the Keychain
    func retrieve(_ key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unknown(status)
        }

        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }

        return string
    }

    /// Delete a value from the Keychain
    func delete(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: self.serviceName,
            kSecAttrAccount as String: key,
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }

        print("🔐 Keychain: Deleted value for key '\(key)'")
    }

    /// Check if a key exists in the Keychain
    func exists(_ key: String) -> Bool {
        do {
            _ = try self.retrieve(key)
            return true
        } catch {
            return false
        }
    }

    /// Generate a unique reference ID for storing keys
    func generateKeyReference() -> String {
        UUID().uuidString
    }

    /// Store API key and return a reference ID
    func storeAPIKey(_ apiKey: String, provider: String) throws -> String {
        let reference = "\(provider)_api_key_\(generateKeyReference())"
        try store(apiKey, for: reference)
        return reference
    }

    /// Retrieve API key using reference ID
    func retrieveAPIKey(reference: String) throws -> String {
        try self.retrieve(reference)
    }

    /// Delete API key using reference ID
    func deleteAPIKey(reference: String) throws {
        try self.delete(reference)
    }
}
