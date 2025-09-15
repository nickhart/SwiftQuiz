//
//  QuizSessionView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import CoreData
import SwiftUI

// swiftlint:disable file_types_order

struct QuizSessionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var sessionViewModel: QuizSessionViewModel
    @EnvironmentObject private var aiService: AIService
    @EnvironmentObject private var settingsService: SettingsService

    @State private var showCopiedConfirmation = false
    @State private var aiEvaluationResult: String = ""
    @State private var showAIEvaluation = false
    @State private var isEvaluating = false
    @State private var showSettings = false

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
                        self.handleAIButtonTap()
                    }, label: {
                        if self.isEvaluating {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "brain")
                        }
                    })
                    .buttonStyle(.bordered)
                    .disabled(self.isEvaluating)
                    .sheet(isPresented: self.$showAIEvaluation) {
                        AIEvaluationSheet(result: self.aiEvaluationResult)
                    }
                    .sheet(isPresented: self.$showSettings) {
                        SettingsView()
                            .environmentObject(self.settingsService)
                            .environmentObject(self.aiService)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 12)
            .background(.background)
        }
    }

    private func handleAIButtonTap() {
        // Check if AI is disabled
        if self.settingsService.aiProvider == .disabled {
            self.showSettings = true
            return
        }

        // Check if API key is missing for the selected provider
        let hasAPIKey = switch self.settingsService.aiProvider {
        case .claude:
            !self.settingsService.claudeAPIKey.isEmpty
        case .openai:
            !self.settingsService.openAIAPIKey.isEmpty
        case .disabled:
            false
        }

        if !hasAPIKey {
            self.showSettings = true
            return
        }

        // All good, proceed with AI evaluation
        self.evaluateWithAI()
    }

    private func evaluateWithAI() {
        guard let question = self.sessionViewModel.currentQuestion else { return }

        // Get user answer text
        let userAnswerText: String = if let existingAnswer = self.sessionViewModel.userAnswer?.answer {
            existingAnswer
        } else if !self.sessionViewModel.currentUserInput
            .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.sessionViewModel.currentUserInput
        } else {
            "No answer provided"
        }

        self.isEvaluating = true

        Task {
            do {
                let result = try await self.aiService.evaluateAnswer(
                    question: question.question ?? "",
                    userAnswer: userAnswerText,
                    correctAnswer: question.answer ?? ""
                )

                await MainActor.run {
                    self.aiEvaluationResult = result
                    self.showAIEvaluation = true
                    self.isEvaluating = false

                    // Create/update UserAnswer after AI evaluation
                    self.createUserAnswerFromAI(userAnswerText: userAnswerText, aiResult: result)
                }
            } catch {
                await MainActor.run {
                    self.aiEvaluationResult = "Error: \(error.localizedDescription)"
                    self.showAIEvaluation = true
                    self.isEvaluating = false
                }
            }
        }
    }

    private func createUserAnswerFromAI(userAnswerText: String, aiResult: String) {
        guard let question = self.sessionViewModel.currentQuestion,
              let context = self.sessionViewModel.context else { return }

        // Check if UserAnswer already exists, if not create one
        let userAnswer: UserAnswer
        if let existingAnswer = self.sessionViewModel.userAnswer {
            userAnswer = existingAnswer
        } else {
            userAnswer = UserAnswer(context: context)
            userAnswer.question = question
            self.sessionViewModel.userAnswer = userAnswer
        }

        // Set the answer text and timestamp
        userAnswer.answer = userAnswerText
        userAnswer.timestamp = Date()

        // Determine if the answer is correct by analyzing AI result
        // We'll look for positive indicators in the AI response
        userAnswer.isCorrect = self.determineCorrectnessFromAI(aiResult: aiResult, question: question)

        // Save the context
        do {
            try context.save()
            print("✅ UserAnswer saved after AI evaluation")
        } catch {
            print("❌ Failed to save UserAnswer: \(error)")
        }
    }

    private func determineCorrectnessFromAI(aiResult: String, question: Question) -> Bool {
        let result = aiResult.lowercased()

        // Look for positive indicators
        let positiveIndicators = [
            "correct", "right", "good", "excellent", "perfect", "accurate",
            "yes", "✅", "👍", "well done", "great job", "exactly",
            "that's right", "you're right", "spot on",
        ]

        // Look for negative indicators
        let negativeIndicators = [
            "incorrect", "wrong", "not quite", "not right", "missed",
            "error", "mistake", "actually", "however", "but",
            "❌", "👎", "try again", "not exactly", "close but",
        ]

        // Count positive vs negative indicators
        let positiveCount = positiveIndicators.reduce(0) { count, indicator in
            count + (result.contains(indicator) ? 1 : 0)
        }

        let negativeCount = negativeIndicators.reduce(0) { count, indicator in
            count + (result.contains(indicator) ? 1 : 0)
        }

        // Default to correct if positive indicators outweigh negative ones
        // This is a heuristic approach - the AI typically gives clear feedback
        return positiveCount > negativeCount
    }
}

struct AIEvaluationSheet: View {
    let result: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(self.result)
                        .padding()
                }
            }
            .navigationTitle("AI Evaluation")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button("Done") {
                            self.dismiss()
                        }
                    }
                }
        }
    }
}

// swiftlint:enable file_types_order
