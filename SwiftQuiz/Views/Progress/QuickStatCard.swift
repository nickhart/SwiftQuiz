//
//  QuickStatCard.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct QuickStatCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: self.icon)
                    .foregroundColor(.blue)
                    .font(.caption)

                Spacer()

                Text(self.change)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(self.isPositive ? .green : .red)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(self.value)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(self.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
