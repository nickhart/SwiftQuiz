//
//  QuizContentView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import CoreData
import SwiftUI

struct QuizContentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settingsService: SettingsService
    @StateObject private var quizSessionService: QuizSessionService
    @State private var currentAnswer: String = ""
    @State private var showingScorecard = false
    @State private var isTransitioningToScorecard = false
    @State private var lastDisplayedQuestion: Question?

    init(context: NSManagedObjectContext) {
        self._quizSessionService = StateObject(wrappedValue: QuizSessionService(
            context: context,
            aiService: AIService.shared,
            settingsService: SettingsService.shared
        ))
    }

    var body: some View {
        ZStack {
            if let session = quizSessionService.currentSession {
                if self.showingScorecard {
                    ScorecardView(
                        session: session,
                        evaluationResult: self.quizSessionService.lastEvaluationResult,
                        onDismiss: {
                            self.dismiss()
                        }
                    )
                } else {
                    self.quizContentView(session: session)
                }
            } else {
                self.loadingView
            }

            if self.quizSessionService.isEvaluating {
                self.evaluatingOverlay
            }
        }
        .onAppear {
            self.startQuiz()
        }
    }

    private func quizContentView(session: QuizSession) -> some View {
        VStack(spacing: 20) {
            self.progressHeader(session: session)

            // Show current question, or last displayed question during transitions
            if let questionToShow = session.currentQuestion ?? lastDisplayedQuestion {
                self.questionCard(question: questionToShow)

                self.answerSection(question: questionToShow)

                self.actionButtons(session: session)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            // Track the current question when view appears
            if let currentQuestion = session.currentQuestion {
                self.lastDisplayedQuestion = currentQuestion
            }
        }
        .onChange(of: session.currentQuestion) { _, newValue in
            // Update last displayed question when question changes (but not when it becomes nil)
            if let newQuestion = newValue {
                self.lastDisplayedQuestion = newQuestion
            }
        }
    }

    private func progressHeader(session: QuizSession) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Quiz")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(min(session.currentQuestionIndex + 1, session.questions.count)) of \(session.questions.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: session.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .animation(.easeInOut(duration: 0.8), value: session.progress)
        }
    }

    private func questionCard(question: Question) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let category = question.category {
                HStack {
                    Text(category.name?.uppercased() ?? "UNKNOWN")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    Spacer()
                }
            }

            Text(question.question ?? "")
                .font(.title3)
                .fontWeight(.medium)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            if question.isMultipleChoice, !question.choiceList.isEmpty {
                self.multipleChoiceSection(choices: question.choiceList)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private func multipleChoiceSection(choices: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(choices.enumerated()), id: \.offset) { _, choice in
                Button(action: {
                    self.currentAnswer = choice
                }, label: {
                    HStack {
                        Image(systemName: self.currentAnswer == choice ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(self.currentAnswer == choice ? .blue : .gray)

                        Text(choice)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)

                        Spacer()
                    }
                    .padding(.vertical, 8)
                })
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private func answerSection(question: Question) -> some View {
        Group {
            if !question.isMultipleChoice {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Answer:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("Type your answer here...", text: self.$currentAnswer, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
            }
        }
    }

    private func actionButtons(session: QuizSession) -> some View {
        HStack(spacing: 16) {
            Button("Skip") {
                self.skipCurrentQuestion(session: session)
            }
            .buttonStyle(.bordered)
            .foregroundColor(.orange)
            .disabled(self.isTransitioningToScorecard)

            Spacer()

            Button("Submit Answer") {
                self.submitAnswer(session: session)
            }
            .buttonStyle(.borderedProminent)
            .disabled(self.currentAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || self
                .isTransitioningToScorecard
            )
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Preparing your quiz...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var evaluatingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))

                Text("Evaluating your quiz...")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("This may take a moment")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(24)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
        }
    }

    private func startQuiz() {
        do {
            _ = try self.quizSessionService.startQuizSession()
        } catch {
            print("Failed to start quiz: \(error)")
            self.dismiss()
        }
    }

    private func submitAnswer(session: QuizSession) {
        guard !self.currentAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Start transition state
        self.isTransitioningToScorecard = true

        // Submit the answer
        self.quizSessionService.submitAnswer(self.currentAnswer)
        self.currentAnswer = ""

        // Handle completion after animation
        self.handleQuizProgression(session: session)
    }

    private func skipCurrentQuestion(session: QuizSession) {
        // Start transition state
        self.isTransitioningToScorecard = true

        // Skip the question
        self.quizSessionService.skipCurrentQuestion()
        self.currentAnswer = ""

        // Handle completion after animation
        self.handleQuizProgression(session: session)
    }

    private func handleQuizProgression(session: QuizSession) {
        // Wait for progress animation to complete, then check if quiz is done
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let updatedSession = self.quizSessionService.currentSession {
                if updatedSession.isCompleted {
                    // Quiz is complete - transition to scorecard and start evaluation
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.showingScorecard = true
                        // Clear the last displayed question when showing scorecard
                        self.lastDisplayedQuestion = nil
                    }

                    // Start evaluation
                    Task {
                        self.quizSessionService.handleMaybeCompletedSession()
                    }
                } else {
                    // More questions - reset transition state
                    self.isTransitioningToScorecard = false
                }
            }
        }
    }
}

#Preview {
    QuizContentView(context: PersistenceController.preview.container.viewContext)
}
