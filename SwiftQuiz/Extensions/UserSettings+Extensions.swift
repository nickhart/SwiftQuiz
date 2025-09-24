import CoreData
import Foundation

extension UserSettings {
    static func fetchOrCreate(context: NSManagedObjectContext) -> UserSettings? {
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", "user_settings")
        request.fetchLimit = 1

        do {
            if let existing = try context.fetch(request).first {
                return existing
            }

            // Create new settings
            let settings = UserSettings(context: context)
            settings.id = "user_settings"
            settings.lastModified = Date()
            settings.enabledCategories = ["Swift"]
            settings.isDebugModeEnabled = false

            try context.save()
            print("✅ UserSettings: Created new settings entity")
            return settings

        } catch {
            print("❌ UserSettings: Failed to fetch or create: \(error)")
            return nil
        }
    }

    func touch() {
        self.lastModified = Date()
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
                self.touch()
            }
        }
    #endif
}
