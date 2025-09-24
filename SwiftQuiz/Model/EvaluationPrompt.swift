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
            "Topic: \(question.category?.name ?? "General")",
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
        lines.append("Evaluate the user answer and respond with valid JSON in this exact format:")
        lines.append("")
        lines.append("{")
        lines.append("  \"score\": \"Complete & Correct\" | \"Partial\" | \"Incomplete\" | \"Incorrect\",")
        lines.append("  \"explanation\": \"Your detailed explanation of why you gave this score\",")
        lines.append("  \"improvements\": \"Specific suggestions for how to improve the answer\",")
        lines.append("  \"correct_answer\": \"What a complete, correct answer should include\"")
        lines.append("}")
        lines.append("")
        lines.append("Important: Respond ONLY with valid JSON. Do not include any text before or after the JSON.")

        return lines.joined(separator: "\n")
    }
}
