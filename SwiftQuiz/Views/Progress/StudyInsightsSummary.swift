//
//  StudyInsightsSummary.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct StudyInsightsSummary: View {
    let insights = [
        StudyInsight(
            type: .streakMilestone,
            title: "Great streak!",
            description: "You're on a 7-day study streak. Keep it up!",
            actionable: true
        ),
        StudyInsight(
            type: .weakAreaDetected,
            title: "Focus on Concurrency",
            description: "Your concurrency scores could use some improvement.",
            actionable: true
        ),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Study Insights")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(self.insights.prefix(2)) { insight in
                    HStack(spacing: 8) {
                        Image(systemName: insight.type == .streakMilestone ? "flame.fill" : "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(insight.type == .streakMilestone ? .orange : .yellow)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(insight.title)
                                .font(.caption)
                                .fontWeight(.medium)

                            Text(insight.description)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
