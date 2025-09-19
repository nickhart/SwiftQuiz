//
//  PerformanceMetric.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

enum PerformanceMetric: String, CaseIterable {
    case score
    case accuracy
    case speed
    case volume
    case studyTime = "study_time"

    var displayName: String {
        switch self {
        case .score: "Quiz Scores"
        case .accuracy: "Accuracy"
        case .speed: "Speed"
        case .volume: "Quiz Volume"
        case .studyTime: "Study Time"
        }
    }

    var unit: String {
        switch self {
        case .score, .accuracy: "%"
        case .speed: "s/question"
        case .volume: "quizzes"
        case .studyTime: "minutes"
        }
    }

    var color: Color {
        switch self {
        case .score: .blue
        case .accuracy: .green
        case .speed: .orange
        case .volume: .purple
        case .studyTime: .red
        }
    }
}
