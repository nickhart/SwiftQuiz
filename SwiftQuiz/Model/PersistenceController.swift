//
//  PersistenceController.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        let importer = CategoryImportService(context: viewContext)
        if let url = Bundle.main.url(forResource: "samplequestions", withExtension: "json") {
            do {
                let count = try importer.importQuestionsSync(from: url, saveAfterImport: true)
                print("Imported \(count) questions for preview")
            } catch {
                print("Failed to import questions for preview: \(error)")
            }
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        self.container = NSPersistentCloudKitContainer(name: "SwiftQuiz")
        if inMemory {
            self.container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        self.container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate.
                // You should not use this function in a shipping application,
                // although it may be useful during development.

                /*
                 * Typical reasons for an error here include:
                 * - The parent directory does not exist, cannot be created, or disallows writing.
                 * - The persistent store is not accessible, due to permissions or data protection
                 *   when the device is locked.
                 * - The device is out of space.
                 * - The store could not be migrated to the current model version.
                 * Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        self.container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
