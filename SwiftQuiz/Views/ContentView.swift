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
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @EnvironmentObject private var viewModel: MainViewModel

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
            NavigationStack {
                switch self.coordinator.selectedDestination {
                case .todaysQuiz: TodaysQuizView()
                case .analytics:
                    VStack {
                        Text("Analytics")
                            .font(.largeTitle)
                        Text("Coming Soon")
                            .foregroundColor(.secondary)
                    }
                case .questionBank: QuestionBrowserView()
                case .settings: SettingsView()
                case .none:
                    Label("Select an item from the sidebar", systemImage: "arrow.left")
                        .foregroundColor(.secondary)
                }
            }
        }
        .sqNavigationTitle("Swift Quiz", displayMode: SQNavigationBarDisplayMode.inline)
        #if os(iOS)
            .sheet(isPresented: self.$coordinator.showQuizModal) {
                QuizModalView(context: self.viewContext) // Pass context directly
            }
            .fullScreenCover(isPresented: self.$coordinator.showOnboardingModal) {
                OnboardingView()
                    .environmentObject(self.aiService)
            }
        #elseif os(macOS)
            .sheet(isPresented: self.$coordinator.showQuizModal) {
                QuizModalView(context: self.viewContext)
                    .frame(minWidth: 600, minHeight: 700)
            }
            .sheet(isPresented: self.$coordinator.showOnboardingModal) {
                OnboardingView()
                    .environmentObject(self.aiService)
                    .frame(minWidth: 600, minHeight: 700)
            }
        #endif
            .onAppear {
                self.viewModel.importQuestionsIfNeeded(using: self.viewContext)

                // Show onboarding for first-time users
                if !UserDefaults.standard.bool(forKey: "has_completed_onboarding") {
                    self.coordinator.showOnboarding()
                }

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
