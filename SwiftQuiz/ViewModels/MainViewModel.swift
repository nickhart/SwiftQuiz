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

        assert(context.persistentStoreCoordinator != nil)
        let importer = QuestionImportService(context: context)

        importer.importAllQuestionFiles { result in
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
