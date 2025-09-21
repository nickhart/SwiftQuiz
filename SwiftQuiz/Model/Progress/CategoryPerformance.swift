//
//  CategoryPerformance.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct CategoryPerformance: Identifiable, Codable {
    let id: UUID
    let name: String
    let icon: String?
    let totalQuestions: Int
    let correctAnswers: Int
    let score: Double // 0.0 to 1.0
    let timeSpent: TimeInterval? // in minutes
    let lastStudied: Date?
    let difficulty: Difficulty?
    let subcategories: [String]?

    // Convenience initializer for quiz session results (simpler)
    init(category: String, totalQuestions: Int, correctAnswers: Int, score: Double) {
        self.id = UUID()
        self.name = category
        self.icon = nil
        self.totalQuestions = totalQuestions
        self.correctAnswers = correctAnswers
        self.score = score
        self.timeSpent = nil
        self.lastStudied = nil
        self.difficulty = nil
        self.subcategories = nil
    }

    // Full initializer for analytics view (detailed)
    init(name: String, icon: String, totalQuestions: Int, correctAnswers: Int,
         score: Double, timeSpent: TimeInterval, lastStudied: Date,
         difficulty: Difficulty, subcategories: [String]) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.totalQuestions = totalQuestions
        self.correctAnswers = correctAnswers
        self.score = score
        self.timeSpent = timeSpent
        self.lastStudied = lastStudied
        self.difficulty = difficulty
        self.subcategories = subcategories
    }

    var accuracy: Double {
        self.totalQuestions > 0 ? Double(self.correctAnswers) / Double(self.totalQuestions) : 0
    }

    var averageScore: Double {
        self.score
    }

    var questionsAnswered: Int {
        self.totalQuestions
    }

    var scorePercentage: Int {
        Int(self.score * 100)
    }

    var performanceLevel: PerformanceLevel {
        PerformanceLevel.from(score: self.score)
    }
}
