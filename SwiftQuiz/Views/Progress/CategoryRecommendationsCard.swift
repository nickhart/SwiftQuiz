//
//  CategoryRecommendationsCard.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct CategoryRecommendationsCard: View {
    let categories: [CategoryPerformance]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                ForEach(self.recommendations, id: \.title) { recommendation in
                    RecommendationRow(recommendation: recommendation)
                }
            }
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private var recommendations: [Recommendation] {
        var recs: [Recommendation] = []

        // Find weakest category
        if let weakest = categories.min(by: { $0.averageScore < $1.averageScore }),
           weakest.averageScore < 0.8 {
            recs.append(Recommendation(
                type: .focusArea,
                title: "Focus on \(weakest.name)",
                description: "Your weakest area needs attention. Consider reviewing fundamentals.",
                category: weakest.name,
                priority: .high
            ))
        }

        // Find categories not studied recently
        let recentThreshold = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
        if let stale = categories.first(where: { $0.lastStudied ?? Date() < recentThreshold }) {
            recs.append(Recommendation(
                type: .review,
                title: "Review \(stale.name)",
                description: "You haven't studied this topic in a while. A quick review would help.",
                category: stale.name,
                priority: .medium
            ))
        }

        // Find strong categories for advancement
        if let strongest = categories.max(by: { $0.averageScore < $1.averageScore }),
           strongest.averageScore > 0.9 {
            recs.append(Recommendation(
                type: .advance,
                title: "Advance in \(strongest.name)",
                description: "You're excelling here! Try more challenging questions in this area.",
                category: strongest.name,
                priority: .low
            ))
        }

        return recs
    }
}
