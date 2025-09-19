//
//  CategoryDetailCard.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct CategoryDetailCard: View {
    let category: CategoryPerformance
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 16) {
            // Main category info
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.isExpanded.toggle()
                }
            }, label: {
                HStack(spacing: 12) {
                    // Icon and name
                    HStack(spacing: 8) {
                        Image(systemName: self.category.icon ?? "unknown.circle")
                            .foregroundColor(.blue)
                            .font(.title3)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(self.category.name)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            HStack(spacing: 8) {
                                Text(
                                    self.category.difficulty?.displayName ?? Difficulty.beginner.displayName
                                )
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    (self.category.difficulty?.color ?? Difficulty.beginner.color)
                                        .opacity(0.2)
                                )
                                .foregroundColor(self.category.difficulty?.color ?? Difficulty.beginner.color)
                                .cornerRadius(8)

                                Text("Last studied \(self.formatRelativeDate(self.category.lastStudied ?? Date()))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()

                    // Performance indicator
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: self.category.performanceLevel.icon)
                                .foregroundColor(self.category.performanceLevel.color)
                                .font(.caption)

                            Text("\(Int(self.category.score * 100))%")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(self.category.performanceLevel.color)
                        }

                        Text(self.category.performanceLevel.displayName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Image(systemName: self.isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            })
            .buttonStyle(PlainButtonStyle())

            // Expanded details
            if self.isExpanded {
                VStack(spacing: 12) {
                    Divider()

                    // Stats grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 12) {
                        CategoryStatItem(
                            title: "Questions",
                            value: "\(self.category.questionsAnswered)",
                            icon: "questionmark.circle.fill"
                        )

                        CategoryStatItem(
                            title: "Accuracy",
                            value: "\(Int(self.category.accuracy * 100))%",
                            icon: "target"
                        )

                        CategoryStatItem(
                            title: "Study Time",
                            value: "\(Int(self.category.timeSpent ?? 0.0))m",
                            icon: "clock.fill"
                        )
                    }

                    // Subcategories
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Topics Covered")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ], spacing: 8) {
                            ForEach(self.category.subcategories ?? [], id: \.self) { subcategory in
                                Text(subcategory)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(8)
                            }
                        }
                    }

                    // Action buttons
                    HStack(spacing: 12) {
                        Button("Practice") {
                            // Navigate to practice for this category
                        }
                        .buttonStyle(.bordered)

                        Button("Review Mistakes") {
                            // Show incorrect answers for this category
                        }
                        .buttonStyle(.bordered)

                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
