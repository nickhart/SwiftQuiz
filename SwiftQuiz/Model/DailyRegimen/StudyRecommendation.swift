//
//  StudyRecommendation.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/18/25.
//

import Foundation
import SwiftUI

struct StudyRecommendation: Codable, Identifiable {
    let id: UUID
    let priority: Priority
    let title: String
    let description: String
    let actionText: String
    let categories: [String]
    let estimatedTimeMinutes: Int

    enum Priority: String, Codable, CaseIterable {
        case high
        case medium
        case low

        var color: Color {
            switch self {
            case .high: .red
            case .medium: .orange
            case .low: .green
            }
        }

        var displayName: String {
            switch self {
            case .high: "High"
            case .medium: "Medium"
            case .low: "Low"
            }
        }
    }

    init(priority: Priority, title: String, description: String, actionText: String,
         categories: [String] = [], estimatedTimeMinutes: Int = 15) {
        self.id = UUID()
        self.priority = priority
        self.title = title
        self.description = description
        self.actionText = actionText
        self.categories = categories
        self.estimatedTimeMinutes = estimatedTimeMinutes
    }
}
