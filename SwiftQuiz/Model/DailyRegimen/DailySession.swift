//
//  DailySession.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/18/25.
//

import Foundation

struct DailySession: Codable, Identifiable {
    let id: UUID
    let date: Date
    var questionsCompleted: Int
    var timeSpent: TimeInterval
    var categoriesStudied: [String]
    var averageScore: Double
    var goalAchieved: Bool
    let streakDay: Int
    var quizSessionIds: [UUID] // Reference to actual quiz sessions

    // Performance metrics
    var correctAnswers: Int
    var totalQuestions: Int
    var improvementAreas: [String]

    init(date: Date = Date(), questionsCompleted: Int = 0, timeSpent: TimeInterval = 0,
         categoriesStudied: [String] = [], averageScore: Double = 0.0, goalAchieved: Bool = false,
         streakDay: Int = 0, quizSessionIds: [UUID] = [], correctAnswers: Int = 0,
         totalQuestions: Int = 0, improvementAreas: [String] = []) {
        self.id = UUID()
        self.date = date
        self.questionsCompleted = questionsCompleted
        self.timeSpent = timeSpent
        self.categoriesStudied = categoriesStudied
        self.averageScore = averageScore
        self.goalAchieved = goalAchieved
        self.streakDay = streakDay
        self.quizSessionIds = quizSessionIds
        self.correctAnswers = correctAnswers
        self.totalQuestions = totalQuestions
        self.improvementAreas = improvementAreas
    }

    var accuracy: Double {
        self.totalQuestions > 0 ? Double(self.correctAnswers) / Double(self.totalQuestions) : 0.0
    }

    var formattedTimeSpent: String {
        let minutes = Int(timeSpent / 60)
        let seconds = Int(timeSpent.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}
