//
//  RecommendationRow.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct RecommendationRow: View {
    let recommendation: Recommendation

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: self.recommendation.type.icon)
                .foregroundColor(self.recommendation.type.color)
                .font(.caption)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(self.recommendation.title)
                    .font(.caption)
                    .fontWeight(.medium)

                Text(self.recommendation.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Circle()
                .fill(self.recommendation.priority.color)
                .frame(width: 6, height: 6)
        }
        .padding(.vertical, 4)
    }
}
