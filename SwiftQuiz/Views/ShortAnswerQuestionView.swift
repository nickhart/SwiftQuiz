//
//  ShortAnswerQuestionView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import SwiftUI
import CoreData

struct ShortAnswerQuestionView: View {
    let question: Question?
    @State private var userInput: String = ""
    @State private var isSubmitted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let question = question {
                Text(question.question ?? "")
                    .font(.headline)

                TextField("Your answer", text: $userInput, onCommit: {
                    isSubmitted = true
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())

                if isSubmitted, let correct = question.answer {
                    let isCorrect = userInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == correct.lowercased()
                    Text(isCorrect ? "✅ Correct!" : "❌ Incorrect. Correct answer: \(correct)")
                        .foregroundColor(isCorrect ? .green : .red)
                        .padding(.top)
                }

                if isSubmitted, let explanation = question.explanation {
                    Text(explanation)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
            } else {
                Text("No question available.")
            }
        }
        .padding()
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let request = Question.fetchRequest()
    request.predicate = NSPredicate(format: "type == %@", "shortAnswer")
    request.fetchLimit = 1

    let result = try? context.fetch(request)
    let question = result?.first
    return ShortAnswerQuestionView(
        question: question)
}
