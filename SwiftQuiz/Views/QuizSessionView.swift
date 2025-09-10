//
//  QuizSessionView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import CoreData
import SwiftUI

struct QuizSessionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var sessionViewModel: QuizSessionViewModel

    @State private var showCopiedConfirmation = false

    var body: some View {
        VStack(spacing: 20) {
            if self.sessionViewModel.currentQuestion != nil {
                QuestionCardView(viewModel: self.sessionViewModel)
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

                FeedbackMenuButton(questionID: self.sessionViewModel.currentQuestion?.id ?? "unknown")

                Button(action: {
                    self.sessionViewModel.advanceToNextUnanswered()
                }, label: {
                    Image(systemName: "arrow.right.circle")
                })
                .buttonStyle(.borderedProminent)

                Button(action: {
                    if let question = sessionViewModel.currentQuestion,
                       let userAnswer = sessionViewModel.userAnswer {
                        let prompt = EvaluationPrompt(
                            question: question,
                            userAnswer: userAnswer,
                            agent: .manualCopyPaste
                        ).renderPromptText()

                        ClipboardService.copy(prompt)

                        self.showCopiedConfirmation = true
                    }
                }, label: {
                    Image(systemName: "brain")
                })
                .buttonStyle(.bordered)
                .alert("Copied AI prompt to clipboard", isPresented: self.$showCopiedConfirmation) {
                    Button("OK", role: .cancel) {}
                }
            }
        }
    }
}
