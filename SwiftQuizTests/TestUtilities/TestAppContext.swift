import CoreData
@testable import SwiftQuiz

@MainActor
class TestAppContext {
    let persistenceController: PersistenceController
    let mockKeychainManager: MockKeychainManager
    let apiKeyService: APIKeyService
    let settingsService: SettingsService

    init() {
        // Use in-memory Core Data stack for testing
        self.persistenceController = PersistenceController(inMemory: true)

        // Use mock keychain for testing
        self.mockKeychainManager = MockKeychainManager()

        // Wire up services with test dependencies
        self.apiKeyService = APIKeyService(
            persistenceController: self.persistenceController,
            keychainManager: self.mockKeychainManager
        )

        self.settingsService = SettingsService(
            persistenceController: self.persistenceController,
            apiKeyService: self.apiKeyService
        )
    }

    func reset() {
        // Clear mock keychain
        self.mockKeychainManager.clear()

        // Clear Core Data context
        let context = self.persistenceController.container.viewContext
        let entities = self.persistenceController.container.managedObjectModel.entities

        for entity in entities {
            if let entityName = entity.name {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

                do {
                    try context.execute(deleteRequest)
                } catch {
                    print("Failed to clear \(entityName): \(error)")
                }
            }
        }

        try? context.save()
    }
}
