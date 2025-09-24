import CoreData
import XCTest
@testable import SwiftQuiz

@MainActor
final class SettingsServiceTests: XCTestCase {
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

    func testCreateOrUpdateAPIKeyNewKey() throws {
        // Given
        let settingsService = self.testContext.settingsService
        let mockKeychain = self.testContext.mockKeychainManager
        let providerName = "TestProvider"
        let keyValue = "test-api-key-12345"

        // When
        try settingsService.createOrUpdateAPIKey(name: providerName, key: keyValue)

        // Then
        let expectedServiceName = "SwiftQuiz.\(providerName).API"
        XCTAssertTrue(mockKeychain.hasKey(key: "api-key", service: expectedServiceName))

        let storedKey = try mockKeychain.retrieveAPIKey(for: expectedServiceName)
        XCTAssertEqual(storedKey, keyValue)

        // Verify Core Data entity was created
        let apiKey = self.testContext.apiKeyService.getAPIKey(named: providerName)
        XCTAssertNotNil(apiKey)
        XCTAssertEqual(apiKey?.name, providerName)
    }

    func testCreateOrUpdateAPIKeyExistingKey() throws {
        // Given
        let settingsService = self.testContext.settingsService
        let mockKeychain = self.testContext.mockKeychainManager
        let providerName = "TestProvider"
        let originalKey = "original-key-12345"
        let updatedKey = "updated-key-67890"

        // Create initial key
        try settingsService.createOrUpdateAPIKey(name: providerName, key: originalKey)

        // When - update existing key
        try settingsService.createOrUpdateAPIKey(name: providerName, key: updatedKey)

        // Then
        let expectedServiceName = "SwiftQuiz.\(providerName).API"
        let storedKey = try mockKeychain.retrieveAPIKey(for: expectedServiceName)
        XCTAssertEqual(storedKey, updatedKey)

        // Verify still only one Core Data entity
        let allKeys = self.testContext.apiKeyService.getAllAPIKeys()
        let providerKeys = allKeys.filter { $0.name == providerName }
        XCTAssertEqual(providerKeys.count, 1)
    }

    func testGetCurrentAPIKey() throws {
        // Given
        let settingsService = self.testContext.settingsService
        let providerName = "TestProvider"
        let keyValue = "test-api-key-12345"

        // Create and set API key
        try settingsService.createOrUpdateAPIKey(name: providerName, key: keyValue)
        let apiKey = self.testContext.apiKeyService.getAPIKey(named: providerName)!
        settingsService.updateSelectedAPIKey(apiKey)

        // When
        let retrievedKey = settingsService.getCurrentAPIKey()

        // Then
        XCTAssertNotNil(retrievedKey)
        XCTAssertEqual(retrievedKey, keyValue)
    }

    func testGetCurrentAPIKeyNoneSelected() {
        // Given
        let settingsService = self.testContext.settingsService

        // When
        let retrievedKey = settingsService.getCurrentAPIKey()

        // Then
        XCTAssertNil(retrievedKey)
    }

    func testUpdateSelectedAPIKey() {
        // Given
        let settingsService = self.testContext.settingsService

        // Initially no selected key
        XCTAssertNil(settingsService.selectedAPIKey)

        // When - create and select key
        let keyValue = "test-api-key-12345"
        try? settingsService.createOrUpdateAPIKey(name: "TestProvider", key: keyValue)
        let apiKey = self.testContext.apiKeyService.getAPIKey(named: "TestProvider")!
        settingsService.updateSelectedAPIKey(apiKey)

        // Then
        XCTAssertNotNil(settingsService.selectedAPIKey)
        XCTAssertEqual(settingsService.selectedAPIKey?.name, "TestProvider")
    }

    func testCategoryManagement() {
        // Given
        let settingsService = self.testContext.settingsService

        // Initially has default category
        XCTAssertTrue(settingsService.isCategoryEnabled("Advanced Swift"))
        XCTAssertFalse(settingsService.isCategoryEnabled("Core Data"))

        // When - enable a category
        settingsService.toggleCategory("Core Data", enabled: true)

        // Then
        XCTAssertTrue(settingsService.isCategoryEnabled("Core Data"))
        XCTAssertEqual(settingsService.enabledCategories.count, 2)

        // When - disable a category
        settingsService.toggleCategory("Advanced Swift", enabled: false)

        // Then
        XCTAssertFalse(settingsService.isCategoryEnabled("Advanced Swift"))
        XCTAssertTrue(settingsService.isCategoryEnabled("Core Data"))
        XCTAssertEqual(settingsService.enabledCategories.count, 1)
    }

    func testAvailableCategories() {
        // Given
        let settingsService = self.testContext.settingsService

        // When
        let categories = settingsService.availableCategories

        // Then
        XCTAssertTrue(categories.contains("Swift"))
        XCTAssertTrue(categories.contains("Advanced Swift"))
        XCTAssertTrue(categories.contains("Core Data"))
        XCTAssertTrue(categories.contains("Core Animation"))
        XCTAssertEqual(categories.count, 4)
    }
}
