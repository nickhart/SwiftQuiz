//
//  SettingsService.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/15/25.
//

import Combine
import CoreData
import Foundation

@MainActor
final class SettingsService: ObservableObject {
    static let shared = SettingsService()

    // MARK: - Published Properties

    @Published var aiProvider: AIProvider = .disabled
    @Published var selectedAPIKey: APIKey?
    @Published var isCloudKitSyncing: Bool = false
    @Published var enabledCategories: Set<String> = ["Advanced Swift"]

    // MARK: - Private Properties

    private let persistenceController: PersistenceController
    private let apiKeyService = APIKeyService.shared
    private let userDefaults = UserDefaults.standard
    private var settings: UserSettings?
    private var cancellables = Set<AnyCancellable>()

    private init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController

        // Load settings immediately
        self.loadSettings()

        // Set up CoreData change notifications
        self.setupCoreDataNotifications()
    }

    // MARK: - Public Methods

    /// Update the selected API key
    func updateSelectedAPIKey(_ apiKey: APIKey?) {
        print("⚙️ Settings: Updating selected API key to: \(apiKey?.name ?? "None")")
        self.selectedAPIKey = apiKey

        guard let settings else {
            print("❌ Settings: No settings entity available")
            return
        }

        settings.selectedAIProvider = apiKey?.name
        settings.touch()
        self.saveContext()
    }

    /// Create or update an API key
    func createOrUpdateAPIKey(name: String, key: String) throws {
        let cleanedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        print("⚙️ Settings: Creating/updating API key for \(name) (length: \(cleanedKey.count))")

        // Debug keychain state before operation
        KeychainManager.shared.debugListAllEntries()

        do {
            if let existingKey = apiKeyService.getAPIKey(named: name) {
                try self.apiKeyService.updateAPIKey(existingKey, newKey: cleanedKey)
            } else {
                _ = try self.apiKeyService.createAPIKey(name: name, key: cleanedKey)
            }
        } catch {
            print("❌ Settings: Keychain operation failed, current state:")
            KeychainManager.shared.debugListAllEntries()
            throw error
        }
    }

    /// Get all available API keys
    var availableAPIKeys: [APIKey] {
        self.apiKeyService.getAllAPIKeys()
    }

    /// Get the current API key value for the selected provider
    func getCurrentAPIKey() -> String? {
        guard let selectedAPIKey else { return nil }

        do {
            return try self.apiKeyService.getAPIKey(for: selectedAPIKey)
        } catch {
            print("❌ Settings: Failed to get API key: \(error)")
            return nil
        }
    }

    // MARK: - Legacy Compatibility Methods

    /// Legacy method for updating AI provider (compatibility)
    func updateProvider(_ provider: AIProvider) {
        print("⚙️ Settings: Updating AI provider to \(provider)")
        self.aiProvider = provider

        // Optionally set selectedAPIKey based on provider
        switch provider {
        case .claude:
            if let claudeKey = apiKeyService.getAPIKey(named: "Claude") {
                self.updateSelectedAPIKey(claudeKey)
            }
        case .openai:
            if let openAIKey = apiKeyService.getAPIKey(named: "OpenAI") {
                self.updateSelectedAPIKey(openAIKey)
            }
        case .disabled:
            self.updateSelectedAPIKey(nil)
        }
    }

    /// Legacy method for updating Claude API key (compatibility)
    func updateClaudeAPIKey(_ key: String) {
        do {
            try self.createOrUpdateAPIKey(name: "Claude", key: key)
            // Set as selected provider if we don't have one
            if self.selectedAPIKey == nil {
                let claudeKey = self.apiKeyService.getAPIKey(named: "Claude")
                self.updateSelectedAPIKey(claudeKey)
            }
        } catch {
            print("❌ Failed to update Claude API key: \(error)")
        }
    }

    /// Legacy method for updating OpenAI API key (compatibility)
    func updateOpenAIAPIKey(_ key: String) {
        do {
            try self.createOrUpdateAPIKey(name: "OpenAI", key: key)
            // Set as selected provider if we don't have one
            if self.selectedAPIKey == nil {
                let openAIKey = self.apiKeyService.getAPIKey(named: "OpenAI")
                self.updateSelectedAPIKey(openAIKey)
            }
        } catch {
            print("❌ Failed to update OpenAI API key: \(error)")
        }
    }

    /// Legacy property for Claude API key (compatibility)
    var claudeAPIKey: String {
        get {
            guard let claudeKey = apiKeyService.getAPIKey(named: "Claude") else {
                return ""
            }
            do {
                return try self.apiKeyService.getAPIKey(for: claudeKey)
            } catch {
                return ""
            }
        }
        set {
            self.updateClaudeAPIKey(newValue)
        }
    }

    /// Legacy property for OpenAI API key (compatibility)
    var openAIAPIKey: String {
        get {
            guard let openAIKey = apiKeyService.getAPIKey(named: "OpenAI") else { return "" }
            do {
                return try self.apiKeyService.getAPIKey(for: openAIKey)
            } catch {
                return ""
            }
        }
        set {
            self.updateOpenAIAPIKey(newValue)
        }
    }

    /// Test API authentication for the selected provider
    func testCurrentAPIAuthentication() async -> String {
        guard let selectedAPIKey else {
            return "❌ No API key selected"
        }

        guard let apiKey = getCurrentAPIKey() else {
            return "❌ Failed to retrieve API key"
        }

        switch selectedAPIKey.name?.lowercased() ?? "" {
        case "claude", "anthropic":
            return await self.testClaudeAuthentication(apiKey: apiKey)
        case "openai":
            return await self.testOpenAIAuthentication(apiKey: apiKey)
        default:
            return "⚠️ Unknown provider: \(selectedAPIKey.name ?? "nil")"
        }
    }

    func testClaudeAuthentication(apiKey: String) async -> String {
        // This would typically make an API call
        // For now, just validate the key format
        if apiKey.hasPrefix("sk-ant-"), apiKey.count > 50 {
            "✅ API key format appears valid"
        } else {
            "⚠️ API key format may be invalid"
        }
    }

    func testOpenAIAuthentication(apiKey: String) async -> String {
        // Test with a simple API call
        do {
            var request = URLRequest(url: URL(string: "https://api.openai.com/v1/models")!)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    return "✅ OpenAI API key is valid"
                case 401:
                    return "❌ Invalid OpenAI API key"
                case 429:
                    return "⚠️ Rate limited - key appears valid but quota exceeded"
                default:
                    return "⚠️ Unexpected response: \(httpResponse.statusCode)"
                }
            }
        } catch {
            return "❌ Network error: \(error.localizedDescription)"
        }

        return "⚠️ Unable to validate API key"
    }

    /// Available question categories
    var availableCategories: [String] {
        ["Swift", "Advanced Swift", "Core Data", "Core Animation"]
    }

    /// Toggle a category on/off
    func toggleCategory(_ category: String, enabled: Bool) {
        if enabled {
            self.enabledCategories.insert(category)
        } else {
            self.enabledCategories.remove(category)
        }
        self.saveCategoriesToSettings()
    }

    /// Check if a category is enabled
    func isCategoryEnabled(_ category: String) -> Bool {
        self.enabledCategories.contains(category)
    }

    #if DEBUG
        /// Get debug mode enabled state
        var isDebugModeEnabled: Bool {
            get {
                self.settings?.isDebugModeEnabled ?? false
            }
            set {
                self.settings?.isDebugModeEnabled = newValue
                self.settings?.touch()
                self.saveContext()
            }
        }

        /// Get debug evaluation mode
        var debugEvaluationMode: DebugEvaluationMode {
            get {
                self.settings?.debugEvaluationMode ?? .useAI
            }
            set {
                self.settings?.debugEvaluationMode = newValue
                self.saveContext()
            }
        }

        /// Save settings (for debug settings that don't automatically trigger save)
        func saveSettings() {
            self.saveContext()
        }
    #endif

    // MARK: - Private Methods

    private func loadSettings() {
        let context = self.persistenceController.container.viewContext

        // Fetch or create settings
        settings = UserSettings.fetchOrCreate(context: context)

        guard let settings else {
            print("❌ Settings: Failed to load or create settings")
            return
        }

        // Load selected API provider
        if let selectedProviderID = settings.selectedAIProvider {
            self.selectedAPIKey = self.apiKeyService.getAPIKey(named: selectedProviderID)
        }

        // Load categories
        if let enabledCats = settings.enabledCategories {
            self.enabledCategories = Set(enabledCats)
        } else {
            self.enabledCategories = ["Advanced Swift"]
        }

        print(
            """
            ⚙️ Settings: Loaded settings - Selected API Key: \(self.selectedAPIKey?.name ?? "None"), \
            Categories: \(self.enabledCategories)
            """
        )
    }

    private func saveContext() {
        let context = self.persistenceController.container.viewContext

        guard context.hasChanges else { return }

        do {
            try context.save()
            print("✅ Settings: Saved to CoreData")
        } catch {
            print("❌ Settings: Failed to save context: \(error)")
        }
    }

    private func setupCoreDataNotifications() {
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .compactMap { notification in
                notification.object as? NSManagedObjectContext
            }
            .filter { context in
                context == self.persistenceController.container.viewContext ||
                    context.parent == self.persistenceController.container.viewContext
            }
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.loadSettings()
                }
            }
            .store(in: &self.cancellables)
    }

    private func loadCategoriesFromUserDefaults() {
        let categoriesArray = self.userDefaults.stringArray(forKey: "enabled_categories") ?? ["Swift"]
        self.enabledCategories = Set(categoriesArray)
    }

    private func saveCategoriesToSettings() {
        guard let settings else { return }

        settings.enabledCategories = Array(self.enabledCategories)
        settings.touch()
        self.saveContext()
    }
}
