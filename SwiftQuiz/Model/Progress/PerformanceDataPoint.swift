//
//  PerformanceDataPoint.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import Foundation

struct PerformanceDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let score: Double
    let accuracy: Double
    let speed: Double
    let quizzesTaken: Int
    let studyTime: Double

    func value(for metric: PerformanceMetric) -> Double {
        switch metric {
        case .score: self.score * 100
        case .accuracy: self.accuracy * 100
        case .speed: self.speed * 60 // Convert to seconds per question
        case .volume: Double(self.quizzesTaken)
        case .studyTime: self.studyTime
        }
    }
}
