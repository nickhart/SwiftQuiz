//
//  LearningPatternsCard.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct LearningPatternsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Learning Patterns")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                PatternInsight(
                    icon: "clock.fill",
                    iconColor: .blue,
                    title: "Peak Performance Hours",
                    description: "You perform best between 8-10 AM",
                    metric: "20% better"
                )

                PatternInsight(
                    icon: "brain.head.profile",
                    iconColor: .purple,
                    title: "Learning Style",
                    description: "You retain information better with practical examples",
                    metric: "15% improvement"
                )

                PatternInsight(
                    icon: "timer",
                    iconColor: .orange,
                    title: "Optimal Session Length",
                    description: "Your focus peaks in 25-minute sessions",
                    metric: "Best results"
                )

                PatternInsight(
                    icon: "calendar",
                    iconColor: .green,
                    title: "Study Frequency",
                    description: "Daily short sessions work better than weekend marathons",
                    metric: "2x retention"
                )
            }
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
