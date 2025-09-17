//
//  QuizSessionView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import CoreData
import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif
#if canImport(AppKit)
    import AppKit
#endif

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
                    FeedbackMenuButton(questionID: self.sessionViewModel.currentQuestion?.id ?? "unknown")

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            self.sessionViewModel.skipCurrentQuestion()
                        }
                    }, label: {
                        Label("Skip", systemImage: "arrow.right.circle")
                    })
                    .buttonStyle(.bordered)

                    Button(action: {
                        self.handleAIButtonTap()
                    }, label: {
                        if self.isEvaluating {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Label("AI Help", systemImage: "brain")
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
        userAnswer.interactionTypeEnum = .answered

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
    @State private var copyButtonText = "Copy"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Clean feedback text
                    Text(self.cleanedResult)
                        .font(.body)
                        .lineSpacing(4)
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                        .textSelection(.enabled) // Make text selectable

                    // Copy and share buttons for easy sharing
                    HStack(spacing: 12) {
                        Spacer()

                        // Share button as alternative
                        Button(action: {
                            self.shareText(self.cleanedResult)
                        }, label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        })
                        .buttonStyle(.bordered)

                        // Direct copy button
                        Button(action: {
                            guard self.copyButtonText == "Copy" else { return }

                            print("🎯 Copy button tapped")
                            self.copyToClipboard(self.cleanedResult)

                            withAnimation(.easeInOut(duration: 0.2)) {
                                self.copyButtonText = "Copied!"
                            }

                            // Reset button text after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    self.copyButtonText = "Copy"
                                }
                            }
                        }, label: {
                            Label(self.copyButtonText, systemImage: "doc.on.doc")
                        })
                        .buttonStyle(.bordered)
                        .disabled(self.copyButtonText == "Copied!")
                    }
                }
                .padding()
            }
            .navigationTitle("AI Feedback")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            self.dismiss()
                        }
                    }
                }
        }
    }

    // Clean up the AI response by removing any prompt artifacts
    private var cleanedResult: String {
        var cleaned = self.result

        // Remove common prompt artifacts
        let artifactsToRemove = [
            "Here is my evaluation of the student's answer:",
            "**Evaluation:**",
            "Evaluation:",
            "**Response:**",
            "Response:",
            "**Feedback:**",
            "Feedback:",
            "Here's my feedback:",
            "My evaluation:",
        ]

        for artifact in artifactsToRemove {
            cleaned = cleaned.replacingOccurrences(of: artifact, with: "")
        }

        // Clean up extra whitespace and formatting
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned.replacingOccurrences(of: "\\n\\n+", with: "\\n\\n", options: .regularExpression)

        // Check for broken interpolation (literal \(variable) patterns)
        if cleaned.contains("\\(userAnswer)") || cleaned.contains("\\(correctAnswer)") || cleaned
            .contains("\\(question)") {
            return "The AI response had technical issues. Please try asking for feedback again."
        }

        // If the response looks like a template, show a fallback message
        if cleaned.contains("placeholder") || cleaned.contains("template") {
            return "The AI response contained template formatting. Please try asking for feedback again."
        }

        return cleaned.isEmpty ? self.result : cleaned
    }

    private func copyToClipboard(_ text: String) {
        let preview = text.prefix(50)
        print("🔗 Attempting to copy text: \(preview)...")

        #if os(iOS)
            UIPasteboard.general.string = text
            print("📋 iOS: Text copied to clipboard")
        #elseif os(macOS)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            let success = pasteboard.setString(text, forType: .string)
            print("📋 macOS: Copy success = \(success)")
        #endif

        // Verify the copy worked
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            #if os(iOS)
                let copiedText = UIPasteboard.general.string
                let preview = copiedText?.prefix(50) ?? "nil"
                print("✅ Verification - iOS clipboard contains: \(preview)")
            #elseif os(macOS)
                let copiedText = NSPasteboard.general.string(forType: .string)
                let preview = copiedText?.prefix(50) ?? "nil"
                print("✅ Verification - macOS clipboard contains: \(preview)")
            #endif
        }
    }

    private func shareText(_ text: String) {
        #if os(iOS)
            let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                // For iPad, set popover presentation
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = rootViewController.view
                    popover.sourceRect = CGRect(
                        x: rootViewController.view.bounds.midX,
                        y: rootViewController.view.bounds.midY,
                        width: 0,
                        height: 0
                    )
                    popover.permittedArrowDirections = []
                }

                rootViewController.present(activityVC, animated: true)
            }
        #elseif os(macOS)
            // On macOS, just copy to clipboard as sharing is more complex
            self.copyToClipboard(text)
        #endif
    }
}

// swiftlint:enable file_types_order
