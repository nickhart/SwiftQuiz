//
//  BadgeType.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import Foundation

enum BadgeType: String, Codable, CaseIterable {
    // Streak badges
    case firstStreak = "first_streak"
    case weekStreak = "week_streak"
    case monthStreak = "month_streak"
    case hundredDayStreak = "hundred_day_streak"

    // Quiz completion badges
    case firstQuiz = "first_quiz"
    case tenQuizzes = "ten_quizzes"
    case fiftyQuizzes = "fifty_quizzes"
    case hundredQuizzes = "hundred_quizzes"
    case thousandQuizzes = "thousand_quizzes"

    // Performance badges
    case perfectScore = "perfect_score"
    case fivePerfectScores = "five_perfect_scores"
    case swiftExplorer = "swift_explorer"
    case swiftProficient = "swift_proficient"
    case swiftGuru = "swift_guru"

    // Category expert badges
    case basicsExpert = "basics_expert"
    case oopExpert = "oop_expert"
    case protocolsExpert = "protocols_expert"
    case concurrencyExpert = "concurrency_expert"
    case uiExpert = "ui_expert"

    // Special achievement badges
    case earlyBird = "early_bird"
    case nightOwl = "night_owl"
    case speedDemon = "speed_demon"
    case persistent
    case comeback

    var title: String {
        switch self {
        case .firstStreak: "Getting Started"
        case .weekStreak: "Week Warrior"
        case .monthStreak: "Monthly Expert"
        case .hundredDayStreak: "Centurion"
        case .firstQuiz: "First Steps"
        case .tenQuizzes: "Quiz Explorer"
        case .fiftyQuizzes: "Quiz Enthusiast"
        case .hundredQuizzes: "Quiz Expert"
        case .thousandQuizzes: "Quiz Legend"
        case .perfectScore: "Flawless Victory"
        case .fivePerfectScores: "Perfection Streak"
        case .swiftExplorer: "Swift Explorer"
        case .swiftProficient: "Swift Proficient"
        case .swiftGuru: "Swift Expert"
        case .basicsExpert: "Basics Expert"
        case .oopExpert: "OOP Expert"
        case .protocolsExpert: "Protocol Pro"
        case .concurrencyExpert: "Concurrency Champion"
        case .uiExpert: "UI Virtuoso"
        case .earlyBird: "Early Bird"
        case .nightOwl: "Night Owl"
        case .speedDemon: "Speed Demon"
        case .persistent: "Never Give Up"
        case .comeback: "Comeback Kid"
        }
    }

    var description: String {
        switch self {
        case .firstStreak: "Complete your first 3-day study streak"
        case .weekStreak: "Maintain a 7-day study streak"
        case .monthStreak: "Achieve a 30-day study streak"
        case .hundredDayStreak: "Reach an incredible 100-day streak"
        case .firstQuiz: "Complete your first quiz"
        case .tenQuizzes: "Complete 10 quizzes"
        case .fiftyQuizzes: "Complete 50 quizzes"
        case .hundredQuizzes: "Complete 100 quizzes"
        case .thousandQuizzes: "Complete 1,000 quizzes"
        case .perfectScore: "Score 100% on a quiz"
        case .fivePerfectScores: "Score 100% on 5 quizzes"
        case .swiftExplorer: "Achieve 70% average across all categories"
        case .swiftProficient: "Achieve 80% average across all categories"
        case .swiftGuru: "Achieve 90% average across all categories"
        case .basicsExpert: "Excel in Swift Basics (90% average)"
        case .oopExpert: "Expert Object-Oriented Programming"
        case .protocolsExpert: "Become a Protocols expert"
        case .concurrencyExpert: "Conquer Swift Concurrency"
        case .uiExpert: "Dominate SwiftUI and UIKit"
        case .earlyBird: "Complete 10 quizzes before 9 AM"
        case .nightOwl: "Complete 10 quizzes after 10 PM"
        case .speedDemon: "Complete a quiz in under 30 seconds"
        case .persistent: "Study for 30 consecutive days"
        case .comeback: "Recover from a broken streak within 3 days"
        }
    }

    var iconName: String {
        switch self {
        case .firstStreak, .weekStreak, .monthStreak, .hundredDayStreak: "flame.fill"
        case .firstQuiz, .tenQuizzes, .fiftyQuizzes, .hundredQuizzes, .thousandQuizzes: "checkmark.circle.fill"
        case .perfectScore, .fivePerfectScores: "star.fill"
        case .swiftExplorer, .swiftProficient, .swiftGuru: "swift"
        case .basicsExpert, .oopExpert, .protocolsExpert, .concurrencyExpert, .uiExpert: "graduationcap.fill"
        case .earlyBird: "sunrise.fill"
        case .nightOwl: "moon.fill"
        case .speedDemon: "bolt.fill"
        case .persistent: "mountain.2.fill"
        case .comeback: "arrow.clockwise"
        }
    }

    var rarity: BadgeRarity {
        switch self {
        case .firstQuiz, .firstStreak: .common
        case .tenQuizzes, .weekStreak, .perfectScore: .uncommon
        case .fiftyQuizzes, .monthStreak, .fivePerfectScores, .basicsExpert, .earlyBird, .nightOwl: .rare
        case .hundredQuizzes, .swiftExplorer, .swiftProficient, .oopExpert, .protocolsExpert, .speedDemon,
             .persistent: .epic
        case .thousandQuizzes, .hundredDayStreak, .swiftGuru, .concurrencyExpert, .uiExpert, .comeback: .legendary
        }
    }

    var targetValue: Int {
        switch self {
        case .firstStreak: 3
        case .weekStreak: 7
        case .monthStreak: 30
        case .hundredDayStreak: 100
        case .firstQuiz: 1
        case .tenQuizzes: 10
        case .fiftyQuizzes: 50
        case .hundredQuizzes: 100
        case .thousandQuizzes: 1000
        case .perfectScore: 1
        case .fivePerfectScores: 5
        case .earlyBird, .nightOwl: 10
        case .persistent: 30
        default: 1
        }
    }
}

extension BadgeType {
    var category: BadgeCategory {
        switch self {
        case .firstStreak, .weekStreak, .monthStreak, .hundredDayStreak:
            .streaks
        case .firstQuiz, .tenQuizzes, .fiftyQuizzes, .hundredQuizzes, .thousandQuizzes:
            .quizzes
        case .perfectScore, .fivePerfectScores, .swiftExplorer, .swiftProficient, .swiftGuru:
            .performance
        case .basicsExpert, .oopExpert, .protocolsExpert, .concurrencyExpert, .uiExpert:
            .expert
        case .earlyBird, .nightOwl, .speedDemon, .persistent, .comeback:
            .special
        }
    }
}
