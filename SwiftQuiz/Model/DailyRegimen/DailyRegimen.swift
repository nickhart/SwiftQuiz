//
//  DailyRegimen.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/18/25.
//

import Foundation

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
