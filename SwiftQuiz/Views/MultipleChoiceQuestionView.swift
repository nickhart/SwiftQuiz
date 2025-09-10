//
//  MultipleChoiceQuestionView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import SwiftUI

struct MultipleChoiceQuestionView: View {
    let question: Question?
    @State private var selectedAnswer: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let question {
                Text(question.question ?? "")
                    .font(.headline)

                ForEach(question.choiceList, id: \.self) { choice in
                    Button(action: {
                        self.selectedAnswer = choice
                    }, label: {
                        Text(choice)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(self.selectedAnswer == choice ? Color.blue.opacity(0.2) : Color.gray
                                .opacity(0.1)
                            )
                            .cornerRadius(8)
                    })
                }

                if let selected = selectedAnswer, let correct = question.answer {
                    Text(selected == correct ? "✅ Correct!" : "❌ Incorrect. Correct answer: \(correct)")
                        .foregroundColor(selected == correct ? .green : .red)
                        .padding(.top)
                    if let explanation = question.explanation {
                        Text(explanation)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
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
    request.predicate = NSPredicate(format: "type == %@", "multipleChoice")
    request.fetchLimit = 1

    let result = try? context.fetch(request)
    let question = result?.first
    return MultipleChoiceQuestionView(question: question)
}
