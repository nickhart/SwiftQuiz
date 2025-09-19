//
//  StudyInsight.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/18/25.
//

import Foundation

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
