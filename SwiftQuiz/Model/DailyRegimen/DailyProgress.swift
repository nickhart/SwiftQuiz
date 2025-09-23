//
//  DailyProgress.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import Foundation

struct DailyProgress: Codable {
    let current: Int
    let target: Int
    let percentage: Double

    init(current: Int, target: Int) {
        self.current = current
        self.target = target
        self.percentage = target > 0 ? min(1.0, Double(current) / Double(target)) : 0.0
    }

    var isCompleted: Bool {
        self.current >= self.target
    }

    var remainingToComplete: Int {
        max(0, self.target - self.current)
    }
}
