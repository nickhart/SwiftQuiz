//
//  DailyGoal.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/18/25.
//

import Foundation

enum DailyGoal: Codable, CaseIterable {
    case questionCount(Int)
    case timeBasedMinutes(Int)
    case categoryFocus([String])

    static var allCases: [DailyGoal] {
        [
            .questionCount(5),
            .questionCount(10),
            .timeBasedMinutes(15),
            .timeBasedMinutes(30),
            .categoryFocus([]),
        ]
    }

    var displayText: String {
        switch self {
        case let .questionCount(count):
            "\(count) questions per day"
        case let .timeBasedMinutes(minutes):
            "\(minutes) minutes per day"
        case let .categoryFocus(categories):
            categories.isEmpty ? "Focus on weak areas" : "Focus on \(categories.joined(separator: ", "))"
        }
    }

    var targetValue: Int {
        switch self {
        case let .questionCount(count):
            count
        case let .timeBasedMinutes(minutes):
            minutes
        case .categoryFocus:
            5 // Default to 5 questions for category focus
        }
    }
}
