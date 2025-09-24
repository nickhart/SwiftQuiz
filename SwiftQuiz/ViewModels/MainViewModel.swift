//
//  MainViewModel.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import CoreData
import SwiftUI

enum QuestionLoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
}

@MainActor
class MainViewModel: ObservableObject {
    @Published var loadingState: QuestionLoadingState = .idle

    func importQuestionsIfNeeded(using context: NSManagedObjectContext) {
        guard case .idle = self.loadingState else { return }

        self.loadingState = .loading

        Task {
            do {
                let categoryImporter = CategoryImportService(context: context)

                // Import question files with categories
                let questionFiles = ["swift_questions", "swift_advanced", "coredata", "coreanimation"]
                var totalImported = 0

                for filename in questionFiles {
                    do {
                        let result = try categoryImporter.importQuestions(
                            fromJSONFileNamed: filename,
                            saveAfterImport: false
                        )
                        totalImported += result.totalProcessed
                        print("✅ Imported \(result.totalProcessed) questions from \(filename)")
                    } catch ImportError.fileNotFound {
                        print("⚠️ Skipping missing file: \(filename).json")
                    } catch {
                        print("❌ Failed to import \(filename): \(error)")
                    }
                }

                // Save all changes at once
                if context.hasChanges {
                    try context.save()
                }

                print("✅ Questions import completed: \(totalImported) total questions")
                self.loadingState = .loaded
            } catch {
                print("❌ Import failed: \(error)")
                self.loadingState = .error("Failed to import: \(error.localizedDescription)")
            }
        }
    }
}
