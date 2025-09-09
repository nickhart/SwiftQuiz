//
//  BoolQuestionView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import SwiftUI

struct BoolQuestionView: View {
    let question: Question?
    @State private var selectedAnswer: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let question {
                Text(question.question ?? "")
                    .font(.headline)

                HStack(spacing: 20) {
                    ForEach(["True", "False"], id: \.self) { option in
                        Button(action: {
                            self.selectedAnswer = option
                        }, label: {
                            Text(option)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(self.selectedAnswer == option ? Color.blue.opacity(0.2) : Color.gray
                                    .opacity(0.1)
                                )
                                .cornerRadius(8)
                        })
                    }
                }

                if let selected = selectedAnswer, let correct = question.answer {
                    Text(selected == correct ? "✅ Correct!" : "❌ Incorrect. Correct answer: \(correct)")
                        .foregroundColor(selected == correct ? .green : .red)
                        .padding(.top)
                }

                if let explanation = question.explanation {
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
    request.predicate = NSPredicate(format: "type == %@", "bool")
    request.fetchLimit = 1

    let result = try? context.fetch(request)
    let question = result?.first
    return BoolQuestionView(question: question)
}
