//
//  NavigationCoordinator.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/17/25.
//

import Foundation

enum NavigationDestination: String, CaseIterable, Hashable {
    case todaysQuiz = "Today's Quiz"
    case analytics = "Progress & Analytics"
    case questionBank = "Question Bank"
    case settings = "Settings"

    var systemImage: String {
        switch self {
        case .todaysQuiz:
            "brain.head.profile"
        case .analytics:
            "chart.line.uptrend.xyaxis"
        case .questionBank:
            "book.fill"
        case .settings:
            "gear"
        }
    }
}

@MainActor
class NavigationCoordinator: ObservableObject {
    @Published var selectedDestination: NavigationDestination? = .todaysQuiz
    @Published var showQuizModal = false

    func startQuizSession() {
        self.showQuizModal = true
    }

    func dismissQuizModal() {
        self.showQuizModal = false
    }

    func navigateTo(_ destination: NavigationDestination) {
        self.selectedDestination = destination
    }
}
