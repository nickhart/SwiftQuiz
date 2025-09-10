//
//  ContentView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import CoreData
import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @StateObject private var viewModel = MainViewModel()
    @StateObject private var sessionViewModel = QuizSessionViewModel()

    @FetchRequest(
        entity: Question.entity(),
        sortDescriptors: [],
        predicate: nil,
        animation: .default
    )
    private var questions: FetchedResults<Question>

    var body: some View {
        Group {
            switch self.viewModel.loadingState {
            case .idle, .loading:
                VStack {
                    ProgressView("Loading questions...")
                        .progressViewStyle(CircularProgressViewStyle())
                }
            case let .error(message):
                VStack {
                    Text("Error loading questions: \(message)")
                        .foregroundColor(.red)
                    Button("Retry") {
                        self.viewModel
                            .importQuestionsIfNeeded(using: self.viewContext)
                    }
                }
            case .loaded:
                QuizSessionView()
                    .environmentObject(self.sessionViewModel)
            }
        }
        .padding()
        .onAppear {
            self.viewModel.importQuestionsIfNeeded(using: self.viewContext)
            if self.sessionViewModel.context == nil {
                self.sessionViewModel.setup(with: self.viewContext)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
