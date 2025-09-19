//
//  BadgeSection.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct BadgeSection: View {
    let title: String
    let subtitle: String
    let badges: [Badge]
    let showProgress: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(self.title)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(self.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 16) {
                ForEach(self.badges) { badge in
                    BadgeCard(badge: badge, showProgress: self.showProgress)
                }
            }
        }
    }
}
