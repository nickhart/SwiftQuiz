//
//  CategoryPerformanceGrid.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct CategoryPerformanceGrid: View {
    let categories = [
        ("Swift Basics", 0.92, "swift"),
        ("OOP", 0.78, "person.3.fill"),
        ("Protocols", 0.85, "doc.plaintext"),
        ("Concurrency", 0.65, "arrow.triangle.2.circlepath"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Category Performance")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12) {
                ForEach(Array(self.categories.enumerated()), id: \.offset) { _, category in
                    CategoryPerformanceItem(
                        name: category.0,
                        performance: category.1,
                        icon: category.2
                    )
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
