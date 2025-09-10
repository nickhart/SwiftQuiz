//
//  QuizSessionView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import SwiftUI

struct QuizSessionView: View {
    let questions: FetchedResults<Question>
    @Binding var currentIndex: Int

    var body: some View {
        VStack(spacing: 20) {
            if self.questions.indices.contains(self.currentIndex) {
                QuestionCardView(question: self.questions[self.currentIndex])
            } else {
                Text("No questions available.")
            }

            HStack {
                Button(action: {
                    // implement dismiss logic
                }, label: {
                    Image(systemName: "xmark.circle")
                })
                .buttonStyle(.bordered)

                SnoozeMenuButton()

                FeedbackMenuButton(questionID: self.questions[self.currentIndex].id ?? "unknown")

                Button(action: {
                    if self.currentIndex + 1 < self.questions.count {
                        self.currentIndex += 1
                    } else {
                        self.currentIndex = 0
                    }
                }, label: {
                    Image(systemName: "arrow.right.circle")
                })
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
