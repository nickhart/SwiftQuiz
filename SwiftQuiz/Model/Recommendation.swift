//
//  Recommendation.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct Recommendation {
    let type: RecommendationType
    let title: String
    let description: String
    let category: String
    let priority: Priority

    enum RecommendationType {
        case focusArea, review, advance

        var icon: String {
            switch self {
            case .focusArea: "target"
            case .review: "arrow.clockwise"
            case .advance: "arrow.up.right"
            }
        }

        var color: Color {
            switch self {
            case .focusArea: .red
            case .review: .orange
            case .advance: .green
            }
        }
    }

    enum Priority {
        case high, medium, low

        var color: Color {
            switch self {
            case .high: .red
            case .medium: .orange
            case .low: .green
            }
        }
    }
}
