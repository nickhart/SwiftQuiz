//
//  StudyInsight.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/18/25.
//

import SwiftUI

enum InsightFilter: String, CaseIterable {
    case all
    case actionable
    case achievements
    case improvements
    case warnings

    var displayName: String {
        switch self {
        case .all: "All"
        case .actionable: "Actionable"
        case .achievements: "Achievements"
        case .improvements: "Improvements"
        case .warnings: "Warnings"
        }
    }

    var icon: String {
        switch self {
        case .all: "list.bullet"
        case .actionable: "checkmark.circle"
        case .achievements: "star.fill"
        case .improvements: "arrow.up.right"
        case .warnings: "exclamationmark.triangle"
        }
    }
}

struct StudyInsight: Codable, Identifiable {
    let id: UUID
    let type: InsightType
    let title: String
    let description: String
    let actionable: Bool
    let createdDate: Date

    enum InsightType: String, Codable {
        case streakMilestone = "streak_milestone"
        case categoryImprovement = "category_improvement"
        case consistencyTrend = "consistency_trend"
        case weakAreaDetected = "weak_area_detected"
        case performanceDecline = "performance_decline"
        case optimalTimeDetected = "optimal_time_detected"
    }

    init(type: InsightType, title: String, description: String, actionable: Bool = false) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.description = description
        self.actionable = actionable
        self.createdDate = Date()
    }
}

extension StudyInsight.InsightType {
    var icon: String {
        switch self {
        case .streakMilestone: "flame.fill"
        case .categoryImprovement: "arrow.up.right"
        case .consistencyTrend: "chart.line.uptrend.xyaxis"
        case .weakAreaDetected: "exclamationmark.triangle.fill"
        case .performanceDecline: "arrow.down.right"
        case .optimalTimeDetected: "clock.fill"
        }
    }

    var color: Color {
        switch self {
        case .streakMilestone: .orange
        case .categoryImprovement: .green
        case .consistencyTrend: .blue
        case .weakAreaDetected: .red
        case .performanceDecline: .red
        case .optimalTimeDetected: .purple
        }
    }
}
