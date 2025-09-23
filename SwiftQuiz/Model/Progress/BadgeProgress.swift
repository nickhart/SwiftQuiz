//
//  BadgeProgress.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import Foundation

struct BadgeProgress: Codable {
    let current: Int
    let target: Int

    var percentage: Double {
        self.target > 0 ? min(1.0, Double(self.current) / Double(self.target)) : 0.0
    }

    var isComplete: Bool {
        self.current >= self.target
    }
}
