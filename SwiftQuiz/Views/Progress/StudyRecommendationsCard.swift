//
//  StudyRecommendationsCard.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct StudyRecommendationsCard: View {
    let recommendations = [
        StudyRecommendation(
            priority: .high,
            title: "Morning Focus Session",
            description: "Try a 20-minute Swift Concurrency session tomorrow morning",
            actionText: "actionText placeholder",
            categories: ["Swift Concurrency"],
            estimatedTimeMinutes: 20
        ),
        StudyRecommendation(
            priority: .medium,
            title: "Review Memory Management",
            description: "Quick review of ARC and reference cycles",
            actionText: "actionText placeholder",
            categories: ["Memory Management"],
            estimatedTimeMinutes: 15
        ),
        StudyRecommendation(
            priority: .low,
            title: "SwiftUI Practice",
            description: "Continue building on your recent SwiftUI progress",
            actionText: "actionText placeholder",
            categories: ["SwiftUI"],
            estimatedTimeMinutes: 25
        ),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended Next Steps")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                ForEach(Array(self.recommendations.enumerated()), id: \.offset) { index, recommendation in
                    StudyRecommendationRow(recommendation: recommendation, rank: index + 1)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
