//
//  MainViewModel.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import CoreData
import SwiftUI

enum QuestionLoadingState {
    case idle
    case loading
    case loaded
    case error(String)
}

class MainViewModel: ObservableObject {
    @Published var loadingState: QuestionLoadingState = .idle

    private let viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }

    func importQuestionsIfNeeded() {
        guard case .idle = self.loadingState else { return }

        self.loadingState = .loading

        DispatchQueue.global(qos: .userInitiated).async {
            let importer = QuestionImportService(context: self.viewContext)
            guard let url = Bundle.main.url(forResource: "swift_questions", withExtension: "json") else {
                DispatchQueue.main.async {
                    self.loadingState = .error("Missing swift_questions.json")
                }
                return
            }

            do {
                let count = try importer.importQuestionsSync(from: url, saveAfterImport: true)
                print("Imported \(count) questions")
                DispatchQueue.main.async {
                    self.loadingState = .loaded
                }
            } catch {
                DispatchQueue.main.async {
                    self.loadingState = .error("Failed to import: \(error.localizedDescription)")
                }
            }
        }
    }
}
