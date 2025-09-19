//
//  StudyInsightCard.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct StudyInsightCard: View {
    let insight: StudyInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: self.insight.type.icon)
                    .foregroundColor(self.insight.type.color)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(self.insight.title)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(self.formatDate(self.insight.createdDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if self.insight.actionable {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }

            Text(self.insight.description)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(nil)

            if self.insight.actionable {
                HStack(spacing: 12) {
                    Button("Take Action") {
                        // Handle action based on insight type
                        self.handleInsightAction(self.insight)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Dismiss") {
                        // Dismiss insight
                    }
                    .buttonStyle(.bordered)

                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func handleInsightAction(_ insight: StudyInsight) {
        switch insight.type {
        case .weakAreaDetected:
            // Navigate to practice in weak category
            break
        case .optimalTimeDetected:
            // Schedule study reminder for optimal time
            break
        case .performanceDecline:
            // Start review session for declining category
            break
        default:
            break
        }
    }
}
