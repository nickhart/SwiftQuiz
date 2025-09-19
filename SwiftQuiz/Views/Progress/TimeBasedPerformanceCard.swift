//
//  TimeBasedPerformanceCard.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct TimeBasedPerformanceCard: View {
    let timeSlots = [
        ("Morning", "6-12", 0.85, "sunrise.fill"),
        ("Afternoon", "12-18", 0.78, "sun.max.fill"),
        ("Evening", "18-24", 0.82, "moon.fill"),
        ("Night", "0-6", 0.65, "moon.stars.fill"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance by Time of Day")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                ForEach(Array(self.timeSlots.enumerated()), id: \.offset) { _, slot in
                    TimeSlotRow(
                        name: slot.0,
                        timeRange: slot.1,
                        performance: slot.2,
                        icon: slot.3
                    )
                }
            }

            Text("You perform best in the morning hours!")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
