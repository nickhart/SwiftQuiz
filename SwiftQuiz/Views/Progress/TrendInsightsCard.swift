//
//  TrendInsightsCard.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct TrendInsightsCard: View {
    let data: [PerformanceDataPoint]
    let metric: PerformanceMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trend Analysis")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                InsightRow(
                    icon: self.trendIcon,
                    iconColor: self.trendColor,
                    title: self.trendTitle,
                    description: self.trendDescription
                )

                if let bestDay = bestPerformanceDay {
                    InsightRow(
                        icon: "star.fill",
                        iconColor: .yellow,
                        title: "Best Performance",
                        description: """
                        Your best day was \(self
                            .formatDate(bestDay.date)
                        ) with \(Int(bestDay.value(for: self.metric)))\(self.metric.unit)
                        """
                    )
                }

                InsightRow(
                    icon: "target",
                    iconColor: .blue,
                    title: "Recommendation",
                    description: self.recommendation
                )
            }
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private var trendIcon: String {
        if self.isImproving { "arrow.up.right" } else if self.isDecreasing { "arrow.down.right" } else { "arrow.right" }
    }

    private var trendColor: Color {
        if self.isImproving { .green } else if self.isDecreasing { .red } else { .orange }
    }

    private var trendTitle: String {
        if self.isImproving {
            "Improving Trend"
        } else if self.isDecreasing {
            "Declining Trend"
        } else {
            "Stable Performance"
        }
    }

    private var trendDescription: String {
        if self.isImproving {
            "Your \(self.metric.displayName.lowercased()) has been consistently improving over time."
        } else if self.isDecreasing {
            "Your \(self.metric.displayName.lowercased()) shows a declining pattern recently."
        } else {
            "Your \(self.metric.displayName.lowercased()) has remained relatively stable."
        }
    }

    private var recommendation: String {
        switch self.metric {
        case .score:
            self.isImproving ? "Keep up the great work! Try tackling harder categories." :
                "Focus on reviewing incorrect answers and taking practice quizzes."
        case .accuracy:
            "Take your time reading questions carefully to improve accuracy."
        case .speed:
            self.isImproving ? "Great timing! Now focus on maintaining accuracy." :
                "Don't rush - accuracy is more important than speed."
        case .volume:
            "Try to maintain consistent daily practice for best results."
        case .studyTime:
            "Consider setting a daily study goal to build consistent habits."
        }
    }

    private var isImproving: Bool {
        guard self.data.count >= 3 else { return false }
        let recent = self.data.suffix(3).map { $0.value(for: self.metric) }
        return recent.last! > recent.first!
    }

    private var isDecreasing: Bool {
        guard self.data.count >= 3 else { return false }
        let recent = self.data.suffix(3).map { $0.value(for: self.metric) }
        return recent.last! < recent.first!
    }

    private var bestPerformanceDay: PerformanceDataPoint? {
        self.data.max { $0.value(for: self.metric) < $1.value(for: self.metric) }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
