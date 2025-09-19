//
//  AdaptiveSettings.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/18/25.
//

import Foundation

struct AdaptiveSettings: Codable {
    var enableDifficultyProgression: Bool
    var focusOnWeakAreas: Bool
    var spacedRepetitionEnabled: Bool
    var categoryBalancing: Bool

    init(enableDifficultyProgression: Bool = true,
         focusOnWeakAreas: Bool = true,
         spacedRepetitionEnabled: Bool = true,
         categoryBalancing: Bool = true) {
        self.enableDifficultyProgression = enableDifficultyProgression
        self.focusOnWeakAreas = focusOnWeakAreas
        self.spacedRepetitionEnabled = spacedRepetitionEnabled
        self.categoryBalancing = categoryBalancing
    }
}
