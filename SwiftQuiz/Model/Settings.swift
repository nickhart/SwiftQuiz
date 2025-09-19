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

    #if DEBUG
        /// Debug evaluation mode for development/testing (stored in UserDefaults)
        var debugEvaluationMode: DebugEvaluationMode {
            get {
                let rawValue = UserDefaults.standard.string(forKey: "debug_evaluation_mode") ?? "Use AI"
                return DebugEvaluationMode(rawValue: rawValue) ?? .useAI
            }
            set {
                UserDefaults.standard.set(newValue.rawValue, forKey: "debug_evaluation_mode")
                lastModified = Date()
            }
        }

        /// Whether debug mode is enabled (only in DEBUG builds, stored in UserDefaults)
        var isDebugModeEnabled: Bool {
            get {
                UserDefaults.standard.bool(forKey: "debug_mode_enabled")
            }
            set {
                UserDefaults.standard.set(newValue, forKey: "debug_mode_enabled")
                lastModified = Date()
            }
        }
    #endif

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

        #if DEBUG
            // Initialize debug UserDefaults if needed
            if UserDefaults.standard.object(forKey: "debug_mode_enabled") == nil {
                UserDefaults.standard.set(false, forKey: "debug_mode_enabled")
            }
            if UserDefaults.standard.object(forKey: "debug_evaluation_mode") == nil {
                UserDefaults.standard.set(DebugEvaluationMode.useAI.rawValue, forKey: "debug_evaluation_mode")
            }
        #endif

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
