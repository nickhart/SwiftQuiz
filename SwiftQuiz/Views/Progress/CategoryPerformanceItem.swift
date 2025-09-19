//
//  CategoryPerformanceItem.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct CategoryPerformanceItem: View {
    let name: String
    let performance: Double
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: self.icon)
                    .font(.caption)
                    .foregroundColor(.blue)

                Spacer()

                Text("\(Int(self.performance * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(self.performanceColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: self.performance)
                    .progressViewStyle(LinearProgressViewStyle(tint: self.performanceColor))
                    .scaleEffect(x: 1, y: 0.8)

                Text(self.name)
                    .font(.caption2)
                    .foregroundColor(.primary)
            }
        }
        .padding(8)
        .background(Color.secondarySystemBackground)
        .cornerRadius(8)
    }

    private var performanceColor: Color {
        if self.performance >= 0.9 {
            .green
        } else if self.performance >= 0.8 {
            .blue
        } else if self.performance >= 0.7 {
            .orange
        } else {
            .red
        }
    }
}
