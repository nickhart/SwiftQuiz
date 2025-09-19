//
//  Badge.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import Foundation

struct Badge: Identifiable, Codable {
    let id: UUID
    let type: BadgeType
    let title: String
    let description: String
    let iconName: String
    let rarity: BadgeRarity
    let unlockedDate: Date?
    let progress: BadgeProgress?

    var isUnlocked: Bool {
        self.unlockedDate != nil
    }

    init(type: BadgeType, unlockedDate: Date? = nil, progress: BadgeProgress? = nil) {
        self.id = UUID()
        self.type = type
        self.title = type.title
        self.description = type.description
        self.iconName = type.iconName
        self.rarity = type.rarity
        self.unlockedDate = unlockedDate
        self.progress = progress
    }
}
