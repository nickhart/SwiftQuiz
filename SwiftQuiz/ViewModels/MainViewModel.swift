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

        // Clear import metadata to force fresh import (DEBUG)
        let questionFiles = ["swift", "swift_advanced", "coredata", "coreanimation"]
        for filename in questionFiles {
            let key = "lastImport_\(filename)"
            UserDefaults.standard.removeObject(forKey: key)
            print("🔄 DEBUG: Cleared import metadata for \(filename)")
        }

        assert(context.persistentStoreCoordinator != nil)
        let importer = QuestionImportService(context: context)

        importer.importAllQuestionFiles { result in
            Task { @MainActor in
                switch result {
                case let .success(count):
                    print("Imported \(count) questions across all categories")
                    self.loadingState = .loaded
                case let .failure(error):
                    print("Failed to import questions: \(error)")
                    self.loadingState = .error("Failed to import: \(error.localizedDescription)")
                }
            }
        }
    }
}
