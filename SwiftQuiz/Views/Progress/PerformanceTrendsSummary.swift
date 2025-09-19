//
//  PerformanceTrendsSummary.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct PerformanceTrendsSummary: View {
    let timeframe: TimeframeFilter

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Performance Trends")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Simplified trend visualization
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<12) { _ in
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.8), .blue.opacity(0.4)]),
                            startPoint: .bottom,
                            endPoint: .top
                        ))
                        .frame(width: 20, height: CGFloat.random(in: 20...80))
                        .cornerRadius(2)
                }
            }
            .padding(.vertical, 8)

            Text("Your scores are trending upward this \(self.timeframe.displayName.lowercased())")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
