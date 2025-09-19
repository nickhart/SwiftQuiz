//
//  QuestionRowView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/18/25.
//

import CoreData
import SwiftUI

struct QuestionRowView: View {
    let question: Question

    private var isAnswered: Bool {
        self.question.userAnswer != nil
    }

    private var lastAnsweredDate: Date? {
        self.question.userAnswer?.timestamp
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with category and status
            HStack {
                if let category = question.category {
                    Text(category.uppercased())
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }

                Spacer()

                if self.isAnswered {
                    HStack(spacing: 4) {
                        Image(systemName: self.question.userAnswer?
                            .isCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill"
                        )
                        .foregroundColor(self.question.userAnswer?.isCorrect == true ? .green : .red)
                        .font(.caption)

                        if let date = lastAnsweredDate {
                            Text(RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date()))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("Not answered")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Question text
            Text(self.question.question ?? "")
                .font(.subheadline)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            // Difficulty and type indicators
            HStack {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { level in
                        Image(systemName: level <= self.question.difficulty ? "star.fill" : "star")
                            .font(.caption2)
                            .foregroundColor(level <= self.question.difficulty ? .yellow : .gray.opacity(0.3))
                    }
                }

                Text(self.question.typeDescription)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray6))
                    .cornerRadius(4)

                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}
