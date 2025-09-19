//
//  PerformanceLevel.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

enum PerformanceLevel: String, Codable, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case needsImprovement = "Needs Improvement"
    case poor = "Poor"

    var emoji: String {
        switch self {
        case .excellent: "🌟"
        case .good: "👍"
        case .fair: "👌"
        case .needsImprovement: "📈"
        case .poor: "📚"
        }
    }

    var color: Color {
        switch self {
        case .excellent: .green
        case .good: .blue
        case .fair: .orange
        case .needsImprovement: .yellow
        case .poor: .red
        }
    }

    var icon: String {
        switch self {
        case .excellent: "star.fill"
        case .good: "checkmark.circle.fill"
        case .fair: "minus.circle.fill"
        case .needsImprovement: "exclamationmark.triangle.fill"
        case .poor: "xmark.circle.fill"
        }
    }

    var displayName: String {
        switch self {
        case .excellent: "Excellent"
        case .good: "Good"
        case .fair: "Average"
        case .needsImprovement: "Needs Improvement"
        case .poor: "Poor"
        }
    }

    static func from(score: Double) -> PerformanceLevel {
        switch score {
        case 0.9...1.0: .excellent
        case 0.8..<0.9: .good
        case 0.7..<0.8: .fair
        case 0.4..<0.7: .needsImprovement
        default: .poor
        }
    }
}
