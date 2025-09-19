//
//  TimeSlotRow.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct TimeSlotRow: View {
    let name: String
    let timeRange: String
    let performance: Double
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: self.icon)
                .foregroundColor(.blue)
                .font(.caption)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(self.name)
                    .font(.caption)
                    .fontWeight(.medium)

                Text(self.timeRange)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            ProgressView(value: self.performance)
                .progressViewStyle(LinearProgressViewStyle(tint: self.performanceColor))
                .frame(width: 60)

            Text("\(Int(self.performance * 100))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(self.performanceColor)
                .frame(width: 30, alignment: .trailing)
        }
    }

    private var performanceColor: Color {
        if self.performance >= 0.8 { .green } else if self.performance >= 0.7 { .orange } else { .red }
    }
}
