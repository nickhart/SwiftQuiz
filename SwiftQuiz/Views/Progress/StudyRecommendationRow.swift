//
//  StudyRecommendationRow.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct StudyRecommendationRow: View {
    let recommendation: StudyRecommendation
    let rank: Int

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            Text("\(self.rank)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(self.recommendation.priority.color))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(self.recommendation.title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text("\(self.recommendation.estimatedTimeMinutes)m")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                }

                Text(self.recommendation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Text(self.recommendation.categories.joined(separator: ", "))
                    .font(.caption2)
                    .foregroundColor(self.recommendation.priority.color)
            }

            Button("Start") {
                // Start recommended study session
            }
            .buttonStyle(.bordered)
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}
