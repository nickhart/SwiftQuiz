//
//  ScorecardView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/17/25.
//

import SwiftUI

struct ScorecardView: View {
    let session: QuizSession
    let evaluationResult: QuizEvaluationResult?
    let onDismiss: () -> Void

    @State private var animateScore = false
    @State private var showDetailedResults = false

    var body: some View {
        VStack(spacing: 24) {
            self.header

            if let result = evaluationResult {
                self.scoreSection(result: result)
                self.insightsSection(result: result)
                self.detailedResultsButton
            } else {
                self.basicScoreSection
            }

            Spacer()

            self.actionButtons
        }
        .padding()
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                self.animateScore = true
            }
        }
        .sheet(isPresented: self.$showDetailedResults) {
            if let result = evaluationResult {
                DetailedResultsView(session: self.session, result: result)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("🎉")
                .font(.largeTitle)

            Text("Quiz Complete!")
                .font(.title)
                .fontWeight(.bold)

            if let duration = session.duration {
                Text("Completed in \(self.formatDuration(duration))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func scoreSection(result: QuizEvaluationResult) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: self.animateScore ? result.overallScore : 0)
                    .stroke(
                        result.performanceLevel.color == "green" ? .green :
                            result.performanceLevel.color == "blue" ? .blue :
                            result.performanceLevel.color == "orange" ? .orange :
                            result.performanceLevel.color == "yellow" ? .yellow : .red,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1.5), value: self.animateScore)

                VStack {
                    Text("\(result.scorePercentage)%")
                        .font(.title)
                        .fontWeight(.bold)

                    Text(result.performanceLevel.emoji)
                        .font(.title2)
                }
            }

            VStack(spacing: 4) {
                Text(result.performanceLevel.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("\(result.correctAnswers) of \(result.totalQuestions) correct")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if result.skippedQuestions > 0 {
                    Text("\(result.skippedQuestions) skipped")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }

    private var basicScoreSection: some View {
        VStack(spacing: 16) {
            Text("📊")
                .font(.system(size: 60))

            Text("Basic Results")
                .font(.headline)

            let answered = self.session.userAnswers.filter { !$0.isSkipped }.count
            let skipped = self.session.userAnswers.filter(\.isSkipped).count

            VStack(spacing: 4) {
                Text("\(answered) of \(self.session.questions.count) answered")
                    .font(.subheadline)

                if skipped > 0 {
                    Text("\(skipped) skipped")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            Text("AI evaluation was unavailable")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
    }

    private func insightsSection(result: QuizEvaluationResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if !result.insights.isEmpty {
                self.insightCard(title: "Key Insights", items: result.insights, color: .blue)
            }

            if !result.strengths.isEmpty {
                self.insightCard(title: "Strengths", items: result.strengths, color: .green)
            }

            if !result.areasForImprovement.isEmpty {
                self.insightCard(title: "Areas for Improvement", items: result.areasForImprovement, color: .orange)
            }

            if !result.recommendations.isEmpty {
                self.insightCard(title: "Recommendations", items: result.recommendations, color: .purple)
            }
        }
    }

    private func insightCard(title: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)

                Spacer()
            }

            ForEach(items.prefix(2), id: \.self) { item in
                HStack(alignment: .top) {
                    Text("•")
                        .foregroundColor(color)
                    Text(item)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }

            if items.count > 2 {
                Text("+ \(items.count - 2) more")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }

    private var detailedResultsButton: some View {
        Button("View Detailed Results") {
            self.showDetailedResults = true
        }
        .buttonStyle(.bordered)
        .foregroundColor(.blue)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button("Continue to Progress") {
                self.onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)

            Button("Take Another Quiz") {
                // TODO: Implement taking another quiz
                self.onDismiss()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
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
        insights: ["You demonstrate strong understanding of Swift fundamentals", "Good grasp of optionals and safety"],
        recommendations: ["Practice more with closures", "Review memory management concepts"],
        strengths: ["Strong basics", "Good problem-solving approach"],
        areasForImprovement: ["Complex syntax", "Advanced Swift features"],
        evaluationTimestamp: Date()
    )

    ScorecardView(
        session: sampleSession,
        evaluationResult: sampleResult,
        onDismiss: {}
    )
}
