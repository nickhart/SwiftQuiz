//
//  BadgeCollectionView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct BadgeCollectionView: View {
    @State private var selectedCategory: BadgeCategory = .all
    @State private var earnedBadges: [Badge] = []
    @State private var availableBadges: [Badge] = []

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header Stats
                BadgeStatsHeader(earnedCount: self.earnedBadges.count, totalCount: BadgeType.allCases.count)

                // Category Filter
                BadgeCategoryFilter(selectedCategory: self.$selectedCategory)

                // Earned Badges Section
                if !self.earnedBadges.isEmpty {
                    BadgeSection(
                        title: "Earned Achievements",
                        subtitle: "Your accomplishments so far",
                        badges: self.filteredEarnedBadges,
                        showProgress: false
                    )
                }

                // Available Badges Section
                BadgeSection(
                    title: "Available Achievements",
                    subtitle: "Badges you can unlock",
                    badges: self.filteredAvailableBadges,
                    showProgress: true
                )
            }
            .padding()
        }
        .sqNavigationTitle("Achievements", displayMode: SQNavigationBarDisplayMode.large)
        .onAppear {
            Task {
                self.loadBadges()
            }
        }
    }

    private var filteredEarnedBadges: [Badge] {
        self.earnedBadges.filter { badge in
            self.selectedCategory == .all || badge.type.category == self.selectedCategory
        }
    }

    private var filteredAvailableBadges: [Badge] {
        self.availableBadges.filter { badge in
            self.selectedCategory == .all || badge.type.category == self.selectedCategory
        }
    }

    private func loadBadges() {
        // Simulate some earned badges
        self.earnedBadges = [
            Badge(type: .firstQuiz, unlockedDate: Date().addingTimeInterval(-604_800)),
            Badge(type: .tenQuizzes, unlockedDate: Date().addingTimeInterval(-432_000)),
            Badge(type: .perfectScore, unlockedDate: Date().addingTimeInterval(-259_200)),
            Badge(type: .weekStreak, unlockedDate: Date().addingTimeInterval(-172_800)),
        ]

        // Create available badges (not yet earned)
        self.availableBadges = BadgeType.allCases.compactMap { type in
            if !self.earnedBadges.contains(where: { $0.type == type }) {
                return Badge(type: type, progress: self.generateProgress(for: type))
            }
            return nil
        }
    }

    private func generateProgress(for type: BadgeType) -> BadgeProgress? {
        // Simulate progress for different badge types
        switch type {
        case .fiftyQuizzes:
            BadgeProgress(current: 23, target: type.targetValue)
        case .monthStreak:
            BadgeProgress(current: 12, target: type.targetValue)
        case .fivePerfectScores:
            BadgeProgress(current: 2, target: type.targetValue)
        case .hundredQuizzes:
            BadgeProgress(current: 45, target: type.targetValue)
        default:
            BadgeProgress(current: Int.random(in: 0...type.targetValue - 1), target: type.targetValue)
        }
    }
}

#Preview {
    BadgeCollectionView()
}
