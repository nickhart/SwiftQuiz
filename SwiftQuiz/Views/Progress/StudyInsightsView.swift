//
//  StudyInsightsView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct StudyInsightsView: View {
    @State private var insights: [StudyInsight] = []
    @State private var selectedFilter: InsightFilter = .all

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    Text("Study Insights")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Personalized recommendations to improve your learning")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // Filter tabs
                    InsightFilterTabs(selectedFilter: self.$selectedFilter)
                }
                .padding(.horizontal)

                // Insights overview
                InsightsOverviewCard(insights: self.insights)
                    .padding(.horizontal)

                // Active insights
                ForEach(self.filteredInsights) { insight in
                    StudyInsightCard(insight: insight)
                        .padding(.horizontal)
                }

                // Study recommendations
                StudyRecommendationsCard()
                    .padding(.horizontal)

                // Learning patterns
                LearningPatternsCard()
                    .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
        .sqNavigationTitle("Insights", displayMode: SQNavigationBarDisplayMode.inline)
        .onAppear {
            self.loadInsights()
        }
    }

    private var filteredInsights: [StudyInsight] {
        switch self.selectedFilter {
        case .all:
            self.insights
        case .actionable:
            self.insights.filter(\.actionable)
        case .achievements:
            self.insights.filter { $0.type == .streakMilestone }
        case .improvements:
            self.insights.filter { $0.type == .categoryImprovement || $0.type == .consistencyTrend }
        case .warnings:
            self.insights.filter { $0.type == .weakAreaDetected || $0.type == .performanceDecline }
        }
    }

    private func loadInsights() {
        self.insights = [
            StudyInsight(
                type: .streakMilestone,
                title: "7-Day Streak Achieved!",
                description: """
                Congratulations! You've maintained a consistent study habit for a full week.
                This is a great foundation for long-term learning success.
                """,
                actionable: false
            ),
            StudyInsight(
                type: .weakAreaDetected,
                title: "Concurrency Needs Attention",
                description: """
                Your performance in Swift Concurrency topics has dropped to 65%.
                Consider reviewing async/await fundamentals and practicing with structured concurrency examples.
                """,
                actionable: true
            ),
            StudyInsight(
                type: .categoryImprovement,
                title: "SwiftUI Progress",
                description: """
                Your SwiftUI scores have improved by 15% over the past two weeks.
                You're showing consistent growth in state management and view composition.
                """,
                actionable: false
            ),
            StudyInsight(
                type: .optimalTimeDetected,
                title: "Morning Study Sessions",
                description: """
                You perform 20% better during morning study sessions (6-9 AM).
                Consider scheduling more challenging topics during these peak hours.
                """,
                actionable: true
            ),
            StudyInsight(
                type: .consistencyTrend,
                title: "Building Strong Habits",
                description: """
                Your study consistency has improved significantly.
                You're averaging 25 minutes per day, up from 15 minutes last month.
                """,
                actionable: false
            ),
            StudyInsight(
                type: .performanceDecline,
                title: "Memory Management Decline",
                description: """
                Your scores in Memory Management have decreased by 10% this week.
                This might indicate information decay - a quick review could help.
                """,
                actionable: true
            ),
        ]
    }
}

#Preview {
    StudyInsightsView()
}
