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
        VStack(spacing: 0) {
            // Question content area - takes up most of the space
            VStack {
                if self.sessionViewModel.currentQuestion != nil {
                    QuestionCardView(viewModel: self.sessionViewModel)
                        .id(self.sessionViewModel.currentQuestion?.id) // Force view refresh for smooth animation
                } else {
                    Text("No questions available.")
                }
            }
            .frame(maxHeight: .infinity)

            // Fixed control buttons at bottom
            VStack(spacing: 16) {
                Divider()

                HStack(spacing: 16) {
                    Button(action: {
                        // implement dismiss logic
                    }, label: {
                        Image(systemName: "xmark.circle")
                    })
                    .buttonStyle(.bordered)

                    SnoozeMenuButton()

                    FeedbackMenuButton(questionID: self.sessionViewModel.currentQuestion?.id ?? "unknown")

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.sessionViewModel.advanceToNextUnanswered()
                        }
                    }, label: {
                        Image(systemName: "arrow.right.circle")
                    })
                    .buttonStyle(.borderedProminent)

                    Button(action: {
                        guard let question = sessionViewModel.currentQuestion else { return }

                        // Create a user answer object - use existing answer, current input, or placeholder
                        let userAnswerText: String = if let existingAnswer = sessionViewModel.userAnswer?.answer {
                            existingAnswer
                        } else if !self.sessionViewModel.currentUserInput
                            .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            self.sessionViewModel.currentUserInput
                        } else {
                            "[Please provide your answer here]"
                        }

                        // Create a temporary UserAnswer for the evaluation prompt
                        let tempUserAnswer = UserAnswer(context: viewContext)
                        tempUserAnswer.answer = userAnswerText

                        let prompt = EvaluationPrompt(
                            question: question,
                            userAnswer: tempUserAnswer,
                            agent: .manualCopyPaste
                        ).renderPromptText()

                        ClipboardService.copy(prompt)
                        self.showCopiedConfirmation = true

                        // Clean up temporary object (don't save it)
                        self.viewContext.delete(tempUserAnswer)
                    }, label: {
                        Image(systemName: "brain")
                    })
                    .buttonStyle(.bordered)
                    .alert("Copied AI evaluation prompt to clipboard", isPresented: self.$showCopiedConfirmation) {
                        Button("OK", role: .cancel) {}
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 12)
            .background(.background)
        }
    }
}
