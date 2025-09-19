//
//  BadgeCategory.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

enum BadgeCategory: String, CaseIterable {
    case all
    case streaks
    case quizzes
    case performance
    case expert
    case special

    var displayName: String {
        switch self {
        case .all: "All"
        case .streaks: "Streaks"
        case .quizzes: "Quizzes"
        case .performance: "Performance"
        case .expert: "Expert"
        case .special: "Special"
        }
    }

    var icon: String {
        switch self {
        case .all: "square.grid.2x2"
        case .streaks: "flame.fill"
        case .quizzes: "doc.text.fill"
        case .performance: "chart.line.uptrend.xyaxis"
        case .expert: "graduationcap.fill"
        case .special: "star.fill"
        }
    }
}
