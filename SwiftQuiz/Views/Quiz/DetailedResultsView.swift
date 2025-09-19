//
//  DetailedResultsView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/17/25.
//

import SwiftUI

struct DetailedResultsView: View {
    let session: QuizSession
    let result: QuizEvaluationResult
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                self.headerSection

                ForEach(Array(self.session.questions.enumerated()), id: \.offset) { index, question in
                    self.questionResultCard(
                        question: question,
                        questionIndex: index,
                        userAnswer: self.session.userAnswers[safe: index],
                        evaluation: self.result.individualResults.first { $0.questionIndex == index }
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Detailed Results")
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

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Overall Score:")
                    .font(.headline)
                Spacer()
                Text("\(self.result.scorePercentage)%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(self.result.performanceLevel.color)
            }

            HStack {
                Text("Performance Level:")
                    .font(.subheadline)
                Spacer()
                HStack {
                    Text(self.result.performanceLevel.emoji)
                    Text(self.result.performanceLevel.rawValue)
                        .fontWeight(.medium)
                        .foregroundColor(self.result.performanceLevel.color)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private func questionResultCard(question: Question,
                                    questionIndex: Int,
                                    userAnswer: QuizAnswer?,
                                    evaluation: QuestionEvaluationResult?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Question \(questionIndex + 1)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()

                self.resultBadge(evaluation: evaluation, userAnswer: userAnswer)
            }

            Text(question.question ?? "")
                .font(.body)
                .fontWeight(.medium)

            if let userAnswer {
                self.answerSection(userAnswer: userAnswer, evaluation: evaluation)
            }

            if let correctAnswer = question.answer {
                self.correctAnswerSection(correctAnswer: correctAnswer)
            }

            if let evaluation, !evaluation.feedback.isEmpty {
                self.feedbackSection(feedback: evaluation.feedback)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private func resultBadge(evaluation: QuestionEvaluationResult?, userAnswer: QuizAnswer?) -> some View {
        Group {
            if let userAnswer, userAnswer.isSkipped {
                Label("Skipped", systemImage: "minus.circle.fill")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(6)
            } else if let evaluation {
                Label(
                    evaluation.isCorrect ? "Correct" : "Incorrect",
                    systemImage: evaluation.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill"
                )
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((evaluation.isCorrect ? Color.green : Color.red).opacity(0.2))
                .foregroundColor(evaluation.isCorrect ? .green : .red)
                .cornerRadius(6)
            } else {
                Label("No evaluation", systemImage: "questionmark.circle.fill")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.gray)
                    .cornerRadius(6)
            }
        }
    }

    private func answerSection(userAnswer: QuizAnswer, evaluation: QuestionEvaluationResult?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Your Answer:")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            if userAnswer.isSkipped {
                Text("(Skipped)")
                    .font(.body)
                    .italic()
                    .foregroundColor(.orange)
            } else if let answer = userAnswer.answer {
                Text(answer)
                    .font(.body)
                    .padding(8)
                    .background(
                        evaluation?.isCorrect == true ? Color.green.opacity(0.1) :
                            evaluation?.isCorrect == false ? Color.red.opacity(0.1) :
                            Color.gray.opacity(0.15)
                    )
                    .cornerRadius(6)
            }
        }
    }

    private func correctAnswerSection(correctAnswer: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Correct Answer:")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            Text(correctAnswer)
                .font(.body)
                .padding(8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)
        }
    }

    private func feedbackSection(feedback: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("AI Feedback:")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            Text(feedback)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
        }
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    let sampleSession = QuizSession(questions: [])
    let sampleResult = QuizEvaluationResult(
        sessionId: UUID(),
        overallScore: 0.8,
        totalQuestions: 5,
        correctAnswers: 4,
        skippedQuestions: 0,
        individualResults: [],
        insights: [],
        recommendations: [],
        strengths: [],
        areasForImprovement: [],
        evaluationTimestamp: Date()
    )

    DetailedResultsView(session: sampleSession, result: sampleResult)
}
