//
//  Settings.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/15/25.
//

import CoreData
import Foundation

extension Settings {
    /// The singleton settings instance ID
    static let settingsID = "user_settings"

    /// AIProvider enum for type safety
    var aiProviderType: AIProvider {
        get {
            AIProvider(rawValue: aiProvider ?? "None") ?? .disabled
        }
        set {
            aiProvider = newValue.rawValue
            lastModified = Date()
        }
    }

    /// Convenience method to fetch or create the singleton settings
    static func fetchOrCreate(context: NSManagedObjectContext) -> Settings {
        let request: NSFetchRequest<Settings> = Settings.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", self.settingsID)
        request.fetchLimit = 1

        do {
            if let existingSettings = try context.fetch(request).first {
                return existingSettings
            }
        } catch {
            print("❌ Settings: Failed to fetch settings: \(error)")
        }

        // Create new settings if none exist
        let newSettings = Settings(context: context)
        newSettings.id = self.settingsID
        newSettings.aiProvider = AIProvider.disabled.rawValue
        newSettings.lastModified = Date()

        do {
            try context.save()
            print("✅ Settings: Created new settings entity")
        } catch {
            print("❌ Settings: Failed to save new settings: \(error)")
        }

        return newSettings
    }

    /// Update the last modified timestamp
    func touch() {
        lastModified = Date()
    }
}
