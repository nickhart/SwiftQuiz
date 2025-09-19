//
//  ReminderSettings.swift
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
