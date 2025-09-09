//
//  QuestionCardView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import SwiftUI

struct QuestionCardView: View {
    var question: Question
    private var viewModel: QuestionCardViewModel

    init(question: Question) {
        self.question = question
        self.viewModel = QuestionCardViewModel(question: question)
    }

    var body: some View {
        Group {
            switch self.viewModel.question?.questionTypeEnum {
            case .bool:
                BoolQuestionView(question: self.viewModel.question)
            case .multipleChoice:
                MultipleChoiceQuestionView(question: self.viewModel.question)
            case .shortAnswer:
                ShortAnswerQuestionView(question: self.viewModel.question)
            case .freeform:
                FreeformQuestionView(question: self.viewModel.question)
            case .none:
                Text("No question available.")
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)).shadow(radius: 4))
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let placeholderQuestion = Question(context: context)
    QuestionCardView(question: placeholderQuestion)
}
