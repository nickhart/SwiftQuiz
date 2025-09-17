//
//  UserAnswer+Extensions.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/16/25.
//

import Foundation

enum InteractionType: String, Codable, CaseIterable {
    case answered
    case skipped

    var isSkipped: Bool {
        self == .skipped
    }
}

extension UserAnswer {
    // Computed property for interaction type
    var interactionTypeEnum: InteractionType {
        get {
            InteractionType(rawValue: interactionType ?? "answered") ?? .answered
        }
        set {
            interactionType = newValue.rawValue
        }
    }

    // Check if this was a skip interaction
    var wasSkipped: Bool {
        self.interactionTypeEnum.isSkipped
    }

    // Check if this answer should be retried (incorrect or skipped after threshold)
    func shouldRetry(thresholdHours: TimeInterval = 48) -> Bool {
        guard let timestamp else { return true }

        let timeSinceInteraction = Date().timeIntervalSince(timestamp) / 3600 // Convert to hours

        // Retry if it was skipped or answered incorrectly, and enough time has passed
        return timeSinceInteraction >= thresholdHours && (self.wasSkipped || !isCorrect)
    }
}
