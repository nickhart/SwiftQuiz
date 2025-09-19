//
//  StudyStreak.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/18/25.
//

import Foundation

struct StudyStreak: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var lastStudyDate: Date?
    var streakBreakGracePeriod: Int = 1 // Allow 1 day gap without breaking

    init(currentStreak: Int = 0, longestStreak: Int = 0, lastStudyDate: Date? = nil) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastStudyDate = lastStudyDate
    }

    func isStreakActive(asOf date: Date = Date()) -> Bool {
        guard let lastDate = lastStudyDate else { return false }

        let calendar = Calendar.current
        let daysBetween = calendar.dateComponents([.day], from: lastDate, to: date).day ?? 0

        return daysBetween <= self.streakBreakGracePeriod
    }

    func shouldOfferStreakRecovery(asOf date: Date = Date()) -> Bool {
        guard let lastDate = lastStudyDate else { return false }

        let calendar = Calendar.current
        let daysBetween = calendar.dateComponents([.day], from: lastDate, to: date).day ?? 0

        return daysBetween > self.streakBreakGracePeriod && daysBetween <= 3 && self.currentStreak > 0
    }

    mutating func updateStreak(for date: Date, goalAchieved: Bool) {
        let calendar = Calendar.current

        if goalAchieved {
            if let lastDate = lastStudyDate {
                let daysBetween = calendar.dateComponents([.day], from: lastDate, to: date).day ?? 0

                if daysBetween == 1 {
                    // Consecutive day
                    self.currentStreak += 1
                } else if daysBetween > self.streakBreakGracePeriod {
                    // Streak broken
                    self.currentStreak = 1
                }
                // Same day or within grace period - no change
            } else {
                // First study session
                self.currentStreak = 1
            }

            self.longestStreak = max(self.longestStreak, self.currentStreak)
            self.lastStudyDate = date
        }
    }
}
