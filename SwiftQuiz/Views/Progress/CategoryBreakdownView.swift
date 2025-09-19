//
//  CategoryBreakdownView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

enum SortOption: String, CaseIterable {
    case performance
    case questionsAnswered = "questions"
    case timeSpent = "time"
    case alphabetical = "name"
    case lastStudied = "recent"

    var displayName: String {
        switch self {
        case .performance: "Performance"
        case .questionsAnswered: "Questions Answered"
        case .timeSpent: "Time Spent"
        case .alphabetical: "Name"
        case .lastStudied: "Recently Studied"
        }
    }
}

struct CategoryBreakdownView: View {
    @State private var selectedSortOption: SortOption = .performance
    @State private var categories: [CategoryPerformance] = []

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header with sort controls
                VStack(alignment: .leading, spacing: 16) {
                    Text("Category Performance")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    HStack {
                        Text("Sort by:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Menu(self.selectedSortOption.displayName) {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(option.displayName) {
                                    self.selectedSortOption = option
                                    self.sortCategories()
                                }
                            }
                        }
                        .buttonStyle(.bordered)

                        Spacer()
                    }
                }
                .padding(.horizontal)

                // Performance overview chart
                CategoryPerformanceChart(categories: self.categories)
                    .padding(.horizontal)

                // Category list
                ForEach(self.categories) { category in
                    CategoryDetailCard(category: category)
                        .padding(.horizontal)
                }

                // Recommendations section
                CategoryRecommendationsCard(categories: self.categories)
                    .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
        .sqNavigationTitle("Categories", displayMode: SQNavigationBarDisplayMode.inline)
        .onAppear {
            Task {
                self.loadCategoryData()
            }
        }
    }

    private func loadCategoryData() {
        self.categories = [
            CategoryPerformance(
                name: "Swift Basics",
                icon: "swift",
                totalQuestions: 45,
                correctAnswers: 41,
                score: 0.92,
                timeSpent: 120,
                lastStudied: Date().addingTimeInterval(-86400),
                difficulty: .beginner,
                subcategories: ["Variables", "Constants", "Data Types", "Control Flow"]
            ),
            CategoryPerformance(
                name: "Object-Oriented Programming",
                icon: "person.3.fill",
                totalQuestions: 32,
                correctAnswers: 25,
                score: 0.78,
                timeSpent: 95,
                lastStudied: Date().addingTimeInterval(-172_800),
                difficulty: .intermediate,
                subcategories: ["Classes", "Inheritance", "Polymorphism", "Encapsulation"]
            ),
            CategoryPerformance(
                name: "Protocols & Extensions",
                icon: "doc.plaintext",
                totalQuestions: 28,
                correctAnswers: 24,
                score: 0.85,
                timeSpent: 85,
                lastStudied: Date().addingTimeInterval(-259_200),
                difficulty: .intermediate,
                subcategories: ["Protocol Basics", "Extensions", "Associated Types", "Protocol Composition"]
            ),
            CategoryPerformance(
                name: "Swift Concurrency",
                icon: "arrow.triangle.2.circlepath",
                totalQuestions: 18,
                correctAnswers: 12,
                score: 0.65,
                timeSpent: 75,
                lastStudied: Date().addingTimeInterval(-345_600),
                difficulty: .advanced,
                subcategories: ["Async/Await", "Actors", "Tasks", "Structured Concurrency"]
            ),
            CategoryPerformance(
                name: "SwiftUI & UIKit",
                icon: "iphone",
                totalQuestions: 35,
                correctAnswers: 31,
                score: 0.89,
                timeSpent: 110,
                lastStudied: Date().addingTimeInterval(-432_000),
                difficulty: .intermediate,
                subcategories: ["Views", "State Management", "Navigation", "Animations"]
            ),
            CategoryPerformance(
                name: "Memory Management",
                icon: "memorychip",
                totalQuestions: 22,
                correctAnswers: 16,
                score: 0.72,
                timeSpent: 65,
                lastStudied: Date().addingTimeInterval(-518_400),
                difficulty: .advanced,
                subcategories: ["ARC", "Strong/Weak References", "Memory Leaks", "Value vs Reference Types"]
            ),
        ]
        self.sortCategories()
    }

    private func sortCategories() {
        switch self.selectedSortOption {
        case .performance:
            self.categories.sort { $0.score > $1.score }
        case .questionsAnswered:
            self.categories.sort { $0.totalQuestions > $1.totalQuestions }
        case .timeSpent:
            self.categories.sort { ($0.timeSpent ?? 0) > ($1.timeSpent ?? 0) }
        case .alphabetical:
            self.categories.sort { $0.name < $1.name }
        case .lastStudied:
            self.categories.sort { ($0.lastStudied ?? Date.distantPast) > ($1.lastStudied ?? Date.distantPast) }
        }
    }
}

#Preview {
    CategoryBreakdownView()
}
