//
//  PerformanceChart.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct PerformanceChart: View {
    let data: [PerformanceDataPoint]
    let metric: PerformanceMetric
    let timeframe: TimeframeFilter

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(self.metric.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                if let average = averageValue {
                    Text("\(Int(average))\(self.metric.unit)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(self.metric.color)
                }
            }

            // Simple line chart visualization
            GeometryReader { geometry in
                Path { path in
                    guard !self.data.isEmpty else { return }

                    let maxValue = self.data.map { $0.value(for: self.metric) }.max() ?? 1
                    let minValue = self.data.map { $0.value(for: self.metric) }.min() ?? 0
                    let valueRange = maxValue - minValue

                    for (index, point) in self.data.enumerated() {
                        let x = CGFloat(index) / CGFloat(self.data.count - 1) * geometry.size.width
                        let normalizedValue = valueRange > 0 ? (point.value(for: self.metric) - minValue) / valueRange :
                            0.5
                        let y = geometry.size.height - (normalizedValue * geometry.size.height)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(self.metric.color, lineWidth: 3)

                // Data points
                ForEach(Array(self.data.enumerated()), id: \.offset) { index, point in
                    let maxValue = self.data.map { $0.value(for: self.metric) }.max() ?? 1
                    let minValue = self.data.map { $0.value(for: self.metric) }.min() ?? 0
                    let valueRange = maxValue - minValue

                    let x = CGFloat(index) / CGFloat(self.data.count - 1) * geometry.size.width
                    let normalizedValue = valueRange > 0 ? (point.value(for: self.metric) - minValue) / valueRange : 0.5
                    let y = geometry.size.height - (normalizedValue * geometry.size.height)

                    Circle()
                        .fill(self.metric.color)
                        .frame(width: 6, height: 6)
                        .position(x: x, y: y)
                }
            }
            .frame(height: 150)
            .padding(.vertical)
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private var averageValue: Double? {
        guard !self.data.isEmpty else { return nil }
        let total = self.data.reduce(0) { $0 + $1.value(for: self.metric) }
        return total / Double(self.data.count)
    }
}
