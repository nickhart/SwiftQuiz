//
//  CategoryPerformanceChart.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct CategoryPerformanceChart: View {
    let categories: [CategoryPerformance]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Overview")
                .font(.headline)
                .fontWeight(.semibold)

            // Horizontal bar chart
            VStack(spacing: 8) {
                ForEach(self.categories.prefix(6)) { category in
                    HStack(spacing: 12) {
                        // Category name and icon
                        HStack(spacing: 6) {
                            Image(systemName: category.icon ?? "folder.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                                .frame(width: 16)

                            Text(category.name)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .frame(width: 120, alignment: .leading)

                        // Performance bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.systemGray5)
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(category.performanceLevel.color)
                                    .frame(width: geometry.size.width * category.score, height: 8)
                            }
                        }
                        .frame(height: 8)

                        // Score percentage
                        Text("\(Int(category.score * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(category.performanceLevel.color)
                            .frame(width: 35, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
