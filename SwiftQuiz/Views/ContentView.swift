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

    @StateObject private var viewModel: MainViewModel
    @FetchRequest(
        entity: Question.entity(),
        sortDescriptors: [],
        predicate: nil,
        animation: .default
    )
    private var questions: FetchedResults<Question>

    @State private var currentIndex = 0

    init() {
        _viewModel =
            StateObject(wrappedValue: MainViewModel(context: PersistenceController.shared.container.viewContext))
    }

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
                        self.viewModel.importQuestionsIfNeeded()
                    }
                }
            case .loaded:
                QuizSessionView(questions: self.questions, currentIndex: self.$currentIndex)
            }
        }
        .padding()
        .onAppear {
            self.viewModel.importQuestionsIfNeeded()
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
