//
//  BadgeStatsHeader.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct BadgeStatsHeader: View {
    let earnedCount: Int
    let totalCount: Int

    var completionPercentage: Double {
        self.totalCount > 0 ? Double(self.earnedCount) / Double(self.totalCount) : 0
    }

    var body: some View {
        VStack(spacing: 16) {
            // Progress Circle
            ZStack {
                Circle()
                    .stroke(Color.systemGray5, lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: self.completionPercentage)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(self.earnedCount)")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("of \(self.totalCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            VStack(spacing: 4) {
                Text("Achievements Unlocked")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("\(Int(self.completionPercentage * 100))% Complete")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
