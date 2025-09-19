//
//  BadgeIcon.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

enum BadgeSize {
    case small, medium, large

    var circleSize: CGFloat {
        switch self {
        case .small: 30
        case .medium: 40
        case .large: 50
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small: 16
        case .medium: 20
        case .large: 24
        }
    }
}

struct BadgeIcon: View {
    let badge: Badge
    let size: BadgeSize

    var body: some View {
        ZStack {
            Circle()
                .fill(self.rarityGradient)
                .frame(width: self.size.circleSize, height: self.size.circleSize)
                .opacity(self.badge.isUnlocked ? 1.0 : 0.3)

            Image(systemName: self.badge.iconName)
                .font(.system(size: self.size.iconSize, weight: .medium))
                .foregroundColor(.white)
                .opacity(self.badge.isUnlocked ? 1.0 : 0.5)

            if !self.badge.isUnlocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: self.size.iconSize * 0.4))
                    .foregroundColor(.gray)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .frame(width: self.size.iconSize * 0.8, height: self.size.iconSize * 0.8)
                    )
            }
        }
    }

    private var rarityGradient: LinearGradient {
        let colors: [Color] = switch self.badge.rarity {
        case .common:
            [.gray, .gray.opacity(0.7)]
        case .uncommon:
            [.green, .green.opacity(0.7)]
        case .rare:
            [.blue, .blue.opacity(0.7)]
        case .epic:
            [.purple, .purple.opacity(0.7)]
        case .legendary:
            [.orange, .yellow]
        }

        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
