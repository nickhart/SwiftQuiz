//
//  EvaluationPrompt.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

enum EvaluationAgent: String {
    case manualCopyPaste
    case openAI
    case claude
}

struct EvaluationPrompt {
    let question: Question
    let userAnswer: UserAnswer
    let agent: EvaluationAgent
    var expectedAnswer: String?

    func renderPromptText() -> String {
        var lines = [
            "You are a quiz grader for a Swift development training app.",
            "",
            "Topic: \(question.primaryTag ?? "General")",
            "Difficulty: \(self.question.difficulty)",
            "",
            "Question:",
            self.question.question ?? "",
            "",
            "User Answer:",
            self.userAnswer.answer ?? "",
        ]

        if let expected = expectedAnswer ?? question.answer {
            lines.append("")
            lines.append("Expected Answer:")
            lines.append(expected)
        }

        lines.append("")
        lines.append("Evaluate the user answer and reply with:")
        lines.append("- Score (Complete & Correct, Partial, Incomplete or Incorrect)")
        lines.append("- Explanation of your evaluation")
        lines.append("- How you would improve or rewrite the answer (if needed)")

        return lines.joined(separator: "\n")
    }
}
