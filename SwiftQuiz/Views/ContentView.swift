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
    @EnvironmentObject private var aiService: AIService

    @StateObject private var coordinator = NavigationCoordinator()
    @StateObject private var viewModel = MainViewModel()
    // TODO: move this into the viewModel
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "has_completed_onboarding")

//    @FetchRequest(
//        entity: Question.entity(),
//        sortDescriptors: [],
//        predicate: nil,
//        animation: .default
//    )
//    private var questions: FetchedResults<Question>

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            switch self.coordinator.selectedDestination {
            case .todaysQuiz: TodaysQuizView()
            case .analytics: AnalyticsView()
            case .questionBank: QuestionBrowserView()
            case .settings: SettingsView()
            case .none:
                Label("Unhandled destination", systemImage: "questionmark")
            }
        }
        .navigationTitle("Swift Quiz")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        #if os(iOS)
        .sheet(isPresented: self.$coordinator.showQuizModal) {
            QuizModalView(context: self.viewContext) // Pass context directly
        }
        .environmentObject(self.coordinator)
        .environmentObject(self.viewModel)
        .fullScreenCover(isPresented: self.$showOnboarding) {
            OnboardingView()
                .environmentObject(self.aiService)
        }
        #elseif os(macOS)
        .sheet(isPresented: self.$showOnboarding) {
            OnboardingView()
                .environmentObject(self.aiService)
                .frame(minWidth: 600, minHeight: 700)
        }
        #endif
        .onAppear {
            self.viewModel.importQuestionsIfNeeded(using: self.viewContext)

            // Request notification permission after app loads
            if !self.notificationService.isAuthorized {
                Task {
                    await self.notificationService.requestPermission()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openQuizFromNotification)) { _ in
            // User tapped daily reminder notification - launch quiz modal
            if self.viewModel.loadingState == .loaded {
                self.coordinator.startQuizSession()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
