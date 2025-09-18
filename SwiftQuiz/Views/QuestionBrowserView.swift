//
//  QuestionBrowserView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/17/25.
//

import SwiftUI

struct QuestionBrowserView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Question Bank")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Coming Soon")
                .font(.title2)
                .foregroundColor(.secondary)

            Text(
                """
                Browse and search through all available Swift questions.
                Practice specific topics or review questions you've answered before.
                """
            )
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    QuestionBrowserView()
}
