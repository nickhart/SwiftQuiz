//
//  DailyRegimen.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/18/25.
//

import Foundation

struct ReminderSettings: Codable {
    var isEnabled: Bool
    var preferredTime: Date
    var allowFollowUp: Bool
    var streakRecoveryEnabled: Bool

    init(isEnabled: Bool = true,
         preferredTime: Date = Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date()) ?? Date(),
         allowFollowUp: Bool = true,
         streakRecoveryEnabled: Bool = true) {
        self.isEnabled = isEnabled
        self.preferredTime = preferredTime
        self.allowFollowUp = allowFollowUp
        self.streakRecoveryEnabled = streakRecoveryEnabled
    }
}

struct AdaptiveSettings: Codable {
    var enableDifficultyProgression: Bool
    var focusOnWeakAreas: Bool
    var spacedRepetitionEnabled: Bool
    var categoryBalancing: Bool

    init(enableDifficultyProgression: Bool = true,
         focusOnWeakAreas: Bool = true,
         spacedRepetitionEnabled: Bool = true,
         categoryBalancing: Bool = true) {
        self.enableDifficultyProgression = enableDifficultyProgression
        self.focusOnWeakAreas = focusOnWeakAreas
        self.spacedRepetitionEnabled = spacedRepetitionEnabled
        self.categoryBalancing = categoryBalancing
    }
}

struct DailyRegimen: Codable, Identifiable {
    let id: UUID
    var isEnabled: Bool
    var dailyGoal: DailyGoal
    var reminderSettings: ReminderSettings
    var adaptiveSettings: AdaptiveSettings
    var startDate: Date
    var currentStreak: Int
    var longestStreak: Int
    var lastCompletedDate: Date?

    init(id: UUID = UUID(), isEnabled: Bool = true, dailyGoal: DailyGoal = .questionCount(5)) {
        self.id = id
        self.isEnabled = isEnabled
        self.dailyGoal = dailyGoal
        self.reminderSettings = ReminderSettings()
        self.adaptiveSettings = AdaptiveSettings()
        self.startDate = Date()
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastCompletedDate = nil
    }
}
