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
                let taxonomyImporter = TaxonomyImportService(context: context)
                let questionImporter = EnhancedQuestionImportService(context: context)

                try await taxonomyImporter.importTaxonomy(from: "swift_taxonomy")
                print("✅ Taxonomy import completed")

                try await questionImporter.importQuestions(from: "swift_questions")
                print("✅ Questions import completed")

                self.loadingState = .loaded
            } catch {
                print("❌ Import failed: \(error)")
                self.loadingState = .error("Failed to import: \(error.localizedDescription)")
            }
        }
    }
}
