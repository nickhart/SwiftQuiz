//
//  DetailedStatsGrid.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct DetailedStatsGrid: View {
    let data: [PerformanceDataPoint]
    let metric: PerformanceMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detailed Statistics")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12) {
                StatItem(title: "Average", value: self.averageValue, unit: self.metric.unit)
                StatItem(title: "Best", value: self.maxValue, unit: self.metric.unit)
                StatItem(title: "Total Sessions", value: Double(self.data.count), unit: "")
                StatItem(title: "Consistency", value: self.consistency * 100, unit: "%")
            }
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private var averageValue: Double {
        guard !self.data.isEmpty else { return 0 }
        return self.data.reduce(0) { $0 + $1.value(for: self.metric) } / Double(self.data.count)
    }

    private var maxValue: Double {
        self.data.map { $0.value(for: self.metric) }.max() ?? 0
    }

    private var consistency: Double {
        guard !self.data.isEmpty else { return 0 }
        let avg = self.averageValue
        let variance = self.data.reduce(0) { sum, point in
            let diff = point.value(for: self.metric) - avg
            return sum + (diff * diff)
        } / Double(self.data.count)
        let standardDeviation = sqrt(variance)
        return max(0, 1 - (standardDeviation / avg))
    }
}
