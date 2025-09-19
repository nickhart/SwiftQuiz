//
//  BadgeCard.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct BadgeCard: View {
    let badge: Badge
    let showProgress: Bool

    var body: some View {
        VStack(spacing: 8) {
            BadgeIcon(badge: self.badge, size: .large)

            VStack(spacing: 4) {
                Text(self.badge.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(self.badge.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)

                if self.showProgress, let progress = badge.progress {
                    VStack(spacing: 2) {
                        ProgressView(value: progress.percentage)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .scaleEffect(x: 1, y: 0.7)

                        Text("\(progress.current) / \(progress.target)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }

                if self.badge.isUnlocked, let date = badge.unlockedDate {
                    Text("Earned \(self.formatDate(date))")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .padding(.top, 2)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
