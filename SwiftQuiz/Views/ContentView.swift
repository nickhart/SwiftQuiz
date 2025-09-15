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
    @EnvironmentObject private var notificationService: NotificationService

    @StateObject private var viewModel = MainViewModel()
    @StateObject private var sessionViewModel = QuizSessionViewModel()
    @State private var showSettings = false

    @FetchRequest(
        entity: Question.entity(),
        sortDescriptors: [],
        predicate: nil,
        animation: .default
    )
    private var questions: FetchedResults<Question>

    var body: some View {
        NavigationStack {
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
            #if os(macOS)
                .frame(maxWidth: 600, maxHeight: 700)
            #endif
                .navigationTitle("Swift Quiz")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button(action: {
                            self.showSettings = true
                        }, label: {
                            Image(systemName: "gear")
                        })
                    }
                }
                .sheet(isPresented: self.$showSettings) {
                    SettingsView()
                        .environmentObject(self.notificationService)
                }
                .onAppear {
                    self.viewModel.importQuestionsIfNeeded(using: self.viewContext)
                    if self.sessionViewModel.context == nil {
                        self.sessionViewModel.setup(with: self.viewContext, mainViewModel: self.viewModel)
                    }

                    // Request notification permission after app loads
                    if !self.notificationService.isAuthorized {
                        Task {
                            await self.notificationService.requestPermission()
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .openQuizFromNotification)) { _ in
                    // User tapped daily reminder notification - ensure we're showing quiz
                    if self.viewModel.loadingState == .loaded {
                        // Quiz should already be visible, but we could trigger a new question here if needed
                        self.sessionViewModel.advanceToNextUnanswered()
                    }
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
