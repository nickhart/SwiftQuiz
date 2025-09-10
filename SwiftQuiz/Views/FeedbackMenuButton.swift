//
//  FeedbackMenuButton.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import SwiftUI

struct FeedbackMenuButton: View {
    let questionID: String
    var body: some View {
        Menu {
            Button("Confusing") {
                print("Feedback: Confusing - \(self.questionID)")
            }
            Button("Incorrect") {
                print("Feedback: Incorrect - \(self.questionID)")
            }
            Button("Typo") {
                print("Feedback: Typo - \(self.questionID)")
            }
            Button("Verify") {
                print("Feedback: Verify - \(self.questionID)")
            }
        } label: {
            Image(systemName: "ladybug")
        }
        .buttonStyle(.bordered)
    }
}
