//
//  InsightsOverviewCard.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct InsightsOverviewCard: View {
    let insights: [StudyInsight]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Insights Summary")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
            }

            HStack(spacing: 16) {
                InsightSummaryItem(
                    count: self.insights.filter(\.actionable).count,
                    title: "Actionable",
                    icon: "checkmark.circle.fill",
                    color: .blue
                )

                InsightSummaryItem(
                    count: self.insights.filter { $0.type == .streakMilestone }.count,
                    title: "Achievements",
                    icon: "star.fill",
                    color: .yellow
                )

                InsightSummaryItem(
                    count: self.insights.filter { $0.type == .weakAreaDetected || $0.type == .performanceDecline }
                        .count,
                    title: "Warnings",
                    icon: "exclamationmark.triangle.fill",
                    color: .orange
                )

                InsightSummaryItem(
                    count: self.insights.filter { $0.type == .categoryImprovement || $0.type == .consistencyTrend }
                        .count,
                    title: "Improvements",
                    icon: "arrow.up.right",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
