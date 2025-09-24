import CoreData
import Foundation

@MainActor
final class APIKeyService: ObservableObject {
    static let shared = APIKeyService()

    private let persistenceController: PersistenceController
    private let keychainManager = KeychainManager.shared

    private init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - API Key Management

    func createAPIKey(name: String, key: String) throws -> APIKey {
        let context = self.persistenceController.container.viewContext

        let serviceName = "SwiftQuiz.\(name).API"

        // Store API key in Keychain with iCloud sync
        try keychainManager.storeAPIKey(key, for: serviceName)

        // Create CoreData entity
        let apiKey = APIKey(context: context)
        apiKey.id = UUID().uuidString
        apiKey.name = name
        apiKey.serviceName = serviceName
        apiKey.isActive = true
        apiKey.dateAdded = Date()

        try context.save()

        print("✅ APIKeyService: Created API key for \(name)")
        return apiKey
    }

    func updateAPIKey(_ apiKey: APIKey, newKey: String) throws {
        guard let serviceName = apiKey.serviceName else {
            throw NSError(
                domain: "APIKeyService",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "API key has no service name"]
            )
        }

        // Store API key in Keychain (handles both create and update cases)
        try self.keychainManager.storeAPIKey(newKey, for: serviceName)

        // Update CoreData
        apiKey.lastUsed = Date()

        let context = self.persistenceController.container.viewContext
        try context.save()

        print("✅ APIKeyService: Updated API key for \(apiKey.name ?? "unknown")")
    }

    func getAPIKey(for apiKey: APIKey) throws -> String {
        guard let serviceName = apiKey.serviceName else {
            throw NSError(
                domain: "APIKeyService",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "API key has no service name"]
            )
        }
        return try self.keychainManager.retrieveAPIKey(for: serviceName)
    }

    func deleteAPIKey(_ apiKey: APIKey) throws {
        let context = self.persistenceController.container.viewContext

        // Delete from Keychain
        if let serviceName = apiKey.serviceName {
            try self.keychainManager.deleteAPIKey(for: serviceName)
        }

        // Delete from CoreData
        context.delete(apiKey)
        try context.save()

        print("✅ APIKeyService: Deleted API key for \(apiKey.name ?? "unknown")")
    }

    func getAllAPIKeys() -> [APIKey] {
        let context = self.persistenceController.container.viewContext
        let request: NSFetchRequest<APIKey> = APIKey.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \APIKey.name, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("❌ APIKeyService: Failed to fetch API keys: \(error)")
            return []
        }
    }

    func getAPIKey(named: String) -> APIKey? {
        let context = self.persistenceController.container.viewContext
        let request: NSFetchRequest<APIKey> = APIKey.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", named)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("❌ APIKeyService: Failed to fetch API key named \(named): \(error)")
            return nil
        }
    }
}
