//
//  QuizModalView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/17/25.
//

import CoreData
import SwiftUI

struct QuizModalView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var quizSessionService: QuizSessionService
    @State private var currentAnswer: String = ""
    @State private var showingScorecard = false
    @State private var animateProgress = false

    init(context: NSManagedObjectContext) {
        self._quizSessionService = StateObject(wrappedValue: QuizSessionService(context: context))
    }

    var body: some View {
        NavigationView {
            ZStack {
                if let session = quizSessionService.currentSession {
                    if session.isCompleted, !self.quizSessionService.isEvaluating {
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
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        self.quizSessionService.abandonCurrentSession()
                        self.dismiss()
                    }
                }
            }
        }
        .onAppear {
            self.startQuiz()
        }
    }

    private func quizContentView(session: QuizSession) -> some View {
        VStack(spacing: 20) {
            self.progressHeader(session: session)

            if let currentQuestion = session.currentQuestion {
                self.questionCard(question: currentQuestion)

                self.answerSection(question: currentQuestion)

                self.actionButtons(session: session)
            }

            Spacer()
        }
        .padding()
    }

    private func progressHeader(session: QuizSession) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Quiz")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(session.currentQuestionIndex + 1) of \(session.questions.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: session.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(x: self.animateProgress ? 1.0 : 0.0, anchor: .leading)
                .animation(.easeOut(duration: 0.5), value: self.animateProgress)
        }
    }

    private func questionCard(question: Question) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let category = question.primaryTag {
                HStack {
                    Text(category.uppercased())
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
                self.skipCurrentQuestion()
            }
            .buttonStyle(.bordered)
            .foregroundColor(.orange)

            Spacer()

            Button("Submit Answer") {
                self.submitAnswer()
            }
            .buttonStyle(.borderedProminent)
            .disabled(self.currentAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                self.animateProgress = true
            }
        } catch {
            print("Failed to start quiz: \(error)")
            self.dismiss()
        }
    }

    private func submitAnswer() {
        guard !self.currentAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        self.quizSessionService.submitAnswer(self.currentAnswer)
        self.currentAnswer = ""

        self.updateProgressAnimation()
    }

    private func skipCurrentQuestion() {
        self.quizSessionService.skipCurrentQuestion()
        self.currentAnswer = ""

        self.updateProgressAnimation()
    }

    private func updateProgressAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            self.animateProgress = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.5)) {
                self.animateProgress = true
            }
        }
    }
}

#Preview {
    QuizModalView(context: PersistenceController.preview.container.viewContext)
}
