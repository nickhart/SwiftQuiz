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
    @Published var claudeAPIKey: String = ""
    @Published var openAIAPIKey: String = ""
    @Published var isCloudKitSyncing: Bool = false
    @Published var enabledCategories: Set<String> = ["Swift"]

    // MARK: - Private Properties

    private let persistenceController: PersistenceController
    private let keychain = KeychainService.shared
    private let userDefaults = UserDefaults.standard
    private var settings: Settings?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Migration Keys

    private let migrationKey = "settings_migrated_to_coredata"

    private init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController

        // Load settings immediately
        self.loadSettings()

        // Migrate from UserDefaults if needed
        self.migrateFromUserDefaults()

        // Set up CoreData change notifications
        self.setupCoreDataNotifications()
    }

    // MARK: - Public Methods

    /// Update the AI provider
    func updateProvider(_ provider: AIProvider) {
        print("⚙️ Settings: Updating AI provider to: \(provider)")
        self.aiProvider = provider

        guard let settings else {
            print("❌ Settings: No settings entity available")
            return
        }

        settings.aiProviderType = provider
        self.saveContext()
    }

    /// Update Claude API key
    func updateClaudeAPIKey(_ key: String) {
        let cleanedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        print("⚙️ Settings: Updating Claude API key (length: \(cleanedKey.count))")

        self.claudeAPIKey = cleanedKey

        guard let settings else {
            print("❌ Settings: No settings entity available")
            return
        }

        self.updateAPIKeyInKeychain(cleanedKey, currentRef: settings.claudeAPIKeyRef, provider: "claude") { newRef in
            settings.claudeAPIKeyRef = newRef
            settings.touch()
            self.saveContext()
        }
    }

    /// Update OpenAI API key
    func updateOpenAIAPIKey(_ key: String) {
        let cleanedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        print("⚙️ Settings: Updating OpenAI API key (length: \(cleanedKey.count))")

        self.openAIAPIKey = cleanedKey

        guard let settings else {
            print("❌ Settings: No settings entity available")
            return
        }

        self.updateAPIKeyInKeychain(cleanedKey, currentRef: settings.openAIAPIKeyRef, provider: "openai") { newRef in
            settings.openAIAPIKeyRef = newRef
            settings.touch()
            self.saveContext()
        }
    }

    /// Test Claude API authentication
    func testClaudeAuthentication() async -> String {
        guard !self.claudeAPIKey.isEmpty else {
            return "❌ No Claude API key configured"
        }

        // This would typically make an API call
        // For now, just validate the key format
        if self.claudeAPIKey.hasPrefix("sk-ant-"), self.claudeAPIKey.count > 50 {
            return "✅ API key format appears valid"
        } else {
            return "⚠️ API key format may be invalid"
        }
    }

    /// Test OpenAI API authentication
    func testOpenAIAuthentication() async -> String {
        guard !self.openAIAPIKey.isEmpty else {
            return "❌ No OpenAI API key configured"
        }

        // Test with a simple API call
        do {
            var request = URLRequest(url: URL(string: "https://api.openai.com/v1/models")!)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(self.openAIAPIKey)", forHTTPHeaderField: "Authorization")

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
        self.saveCategoriesToUserDefaults()
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
        settings = Settings.fetchOrCreate(context: context)

        guard let settings else {
            print("❌ Settings: Failed to load or create settings")
            return
        }

        // Load provider
        self.aiProvider = settings.aiProviderType

        // Load API keys from Keychain
        if let claudeRef = settings.claudeAPIKeyRef {
            self.claudeAPIKey = self.loadAPIKeyFromKeychain(reference: claudeRef) ?? ""
        }

        if let openAIRef = settings.openAIAPIKeyRef {
            self.openAIAPIKey = self.loadAPIKeyFromKeychain(reference: openAIRef) ?? ""
        }

        // Load categories from UserDefaults
        self.loadCategoriesFromUserDefaults()

        print(
            """
            ⚙️ Settings: Loaded settings - Provider: \(self.aiProvider), \
            Claude key: \(!self.claudeAPIKey.isEmpty), OpenAI key: \(!self.openAIAPIKey.isEmpty), \
            Categories: \(self.enabledCategories)
            """
        )
    }

    private func loadAPIKeyFromKeychain(reference: String) -> String? {
        do {
            return try self.keychain.retrieveAPIKey(reference: reference)
        } catch KeychainService.KeychainError.itemNotFound {
            print("⚠️ Settings: API key not found in Keychain for reference: \(reference)")
            return nil
        } catch {
            print("❌ Settings: Failed to load API key from Keychain: \(error)")
            return nil
        }
    }

    private func updateAPIKeyInKeychain(_ key: String, currentRef: String?, provider: String,
                                        completion: (String?) -> Void) {
        // Delete old key if exists
        if let currentRef {
            do {
                try self.keychain.deleteAPIKey(reference: currentRef)
            } catch {
                print("⚠️ Settings: Failed to delete old API key: \(error)")
            }
        }

        // Store new key if not empty
        if !key.isEmpty {
            do {
                let newRef = try keychain.storeAPIKey(key, provider: provider)
                completion(newRef)
            } catch {
                print("❌ Settings: Failed to store API key in Keychain: \(error)")
                completion(currentRef) // Keep old reference on failure
            }
        } else {
            completion(nil) // No key to store
        }
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

    private func migrateFromUserDefaults() {
        guard !self.userDefaults.bool(forKey: self.migrationKey) else {
            print("⚙️ Settings: Already migrated from UserDefaults")
            return
        }

        print("⚙️ Settings: Starting migration from UserDefaults...")

        // Migrate AI provider
        if let providerString = userDefaults.string(forKey: "ai_provider"),
           let provider = AIProvider(rawValue: providerString) {
            self.updateProvider(provider)
        }

        // Migrate Claude API key
        if let claudeKey = userDefaults.string(forKey: "claude_api_key"), !claudeKey.isEmpty {
            self.updateClaudeAPIKey(claudeKey)
        }

        // Migrate OpenAI API key
        if let openAIKey = userDefaults.string(forKey: "openai_api_key"), !openAIKey.isEmpty {
            self.updateOpenAIAPIKey(openAIKey)
        }

        // Mark migration as completed
        self.userDefaults.set(true, forKey: self.migrationKey)
        self.userDefaults.synchronize()

        // Clean up old keys from UserDefaults
        self.userDefaults.removeObject(forKey: "ai_provider")
        self.userDefaults.removeObject(forKey: "claude_api_key")
        self.userDefaults.removeObject(forKey: "openai_api_key")

        print("✅ Settings: Migration from UserDefaults completed")
    }

    private func loadCategoriesFromUserDefaults() {
        let categoriesArray = self.userDefaults.stringArray(forKey: "enabled_categories") ?? ["Swift"]
        self.enabledCategories = Set(categoriesArray)
    }

    private func saveCategoriesToUserDefaults() {
        let categoriesArray = Array(enabledCategories)
        self.userDefaults.set(categoriesArray, forKey: "enabled_categories")
        self.userDefaults.synchronize()
    }
}
