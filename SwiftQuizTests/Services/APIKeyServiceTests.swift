import CoreData
import XCTest
@testable import SwiftQuiz

@MainActor
final class APIKeyServiceTests: XCTestCase {
    var testContext: TestAppContext!

    override func setUp() async throws {
        try await super.setUp()
        self.testContext = TestAppContext()
    }

    override func tearDown() async throws {
        self.testContext?.reset()
        self.testContext = nil
        try await super.tearDown()
    }

    func testCreateAPIKey() throws {
        // Given
        let apiKeyService = self.testContext.apiKeyService
        let mockKeychain = self.testContext.mockKeychainManager
        let keyName = "TestProvider"
        let keyValue = "test-api-key-12345"

        // When
        let createdKey = try apiKeyService.createAPIKey(name: keyName, key: keyValue)

        // Then
        XCTAssertEqual(createdKey.name, keyName)
        XCTAssertNotNil(createdKey.id)
        XCTAssertNotNil(createdKey.dateAdded)
        XCTAssertTrue(createdKey.isActive)

        // Verify keychain storage
        let expectedServiceName = "SwiftQuiz.\(keyName).API"
        XCTAssertTrue(mockKeychain.hasKey(key: "api-key", service: expectedServiceName))

        let storedKey = try mockKeychain.retrieveAPIKey(for: expectedServiceName)
        XCTAssertEqual(storedKey, keyValue)
    }

    func testUpdateAPIKey() throws {
        // Given
        let apiKeyService = self.testContext.apiKeyService
        let mockKeychain = self.testContext.mockKeychainManager
        let keyName = "TestProvider"
        let originalKey = "original-key-12345"
        let updatedKey = "updated-key-67890"

        let createdKey = try apiKeyService.createAPIKey(name: keyName, key: originalKey)

        // When
        try apiKeyService.updateAPIKey(createdKey, newKey: updatedKey)

        // Then
        let expectedServiceName = "SwiftQuiz.\(keyName).API"
        let storedKey = try mockKeychain.retrieveAPIKey(for: expectedServiceName)
        XCTAssertEqual(storedKey, updatedKey)

        // Verify Core Data update
        XCTAssertNotNil(createdKey.lastUsed)
    }

    func testGetAPIKeyByName() throws {
        // Given
        let apiKeyService = self.testContext.apiKeyService
        let keyName = "TestProvider"
        let keyValue = "test-api-key-12345"

        let createdKey = try apiKeyService.createAPIKey(name: keyName, key: keyValue)

        // When
        let foundKey = apiKeyService.getAPIKey(named: keyName)

        // Then
        XCTAssertNotNil(foundKey)
        XCTAssertEqual(foundKey?.id, createdKey.id)
        XCTAssertEqual(foundKey?.name, keyName)
    }

    func testGetAPIKeyByNameNotFound() {
        // Given
        let apiKeyService = self.testContext.apiKeyService

        // When
        let foundKey = apiKeyService.getAPIKey(named: "NonExistentProvider")

        // Then
        XCTAssertNil(foundKey)
    }

    func testDeleteAPIKey() throws {
        // Given
        let apiKeyService = self.testContext.apiKeyService
        let mockKeychain = self.testContext.mockKeychainManager
        let keyName = "TestProvider"
        let keyValue = "test-api-key-12345"

        let createdKey = try apiKeyService.createAPIKey(name: keyName, key: keyValue)
        let expectedServiceName = "SwiftQuiz.\(keyName).API"

        // Verify it exists first
        XCTAssertTrue(mockKeychain.hasKey(key: "api-key", service: expectedServiceName))

        // When
        try apiKeyService.deleteAPIKey(createdKey)

        // Then
        XCTAssertFalse(mockKeychain.hasKey(key: "api-key", service: expectedServiceName))

        // Verify Core Data deletion
        let foundKey = apiKeyService.getAPIKey(named: keyName)
        XCTAssertNil(foundKey)
    }

    func testGetAllAPIKeys() throws {
        // Given
        let apiKeyService = self.testContext.apiKeyService

        // When - initially empty
        var allKeys = apiKeyService.getAllAPIKeys()

        // Then
        XCTAssertTrue(allKeys.isEmpty)

        // When - add some keys
        _ = try apiKeyService.createAPIKey(name: "Provider1", key: "key1")
        _ = try apiKeyService.createAPIKey(name: "Provider2", key: "key2")
        allKeys = apiKeyService.getAllAPIKeys()

        // Then
        XCTAssertEqual(allKeys.count, 2)
        let names = Set(allKeys.compactMap(\.name))
        XCTAssertEqual(names, Set(["Provider1", "Provider2"]))
    }
}
