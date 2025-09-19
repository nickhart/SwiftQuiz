//
//  RecentBadgesCard.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct RecentBadgesCard: View {
    let recentBadges = [
        Badge(type: .weekStreak, unlockedDate: Date().addingTimeInterval(-86400)),
        Badge(type: .perfectScore, unlockedDate: Date().addingTimeInterval(-172_800)),
        Badge(type: .tenQuizzes, unlockedDate: Date().addingTimeInterval(-259_200)),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Achievements")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                ForEach(self.recentBadges) { badge in
                    BadgeIcon(badge: badge, size: .medium)
                }

                Spacer()
            }

            Text("\(self.recentBadges.count) new badges earned recently")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
