//
//  FeedbackMenuButton.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import SwiftUI

struct FeedbackMenuButton: View {
    let questionID: String
    @State private var showFeedbackPopover = false

    var body: some View {
        Button(action: {
            self.showFeedbackPopover = true
        }, label: {
            Image(systemName: "ladybug")
        })
        .buttonStyle(.bordered)
        .popover(isPresented: self.$showFeedbackPopover) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Report Issue")
                    .font(.headline)
                    .padding(.bottom, 4)

                Button("Confusing") {
                    self.showFeedbackPopover = false
                    print("Feedback: Confusing - \(self.questionID)")
                }

                Button("Incorrect") {
                    self.showFeedbackPopover = false
                    print("Feedback: Incorrect - \(self.questionID)")
                }

                Button("Typo") {
                    self.showFeedbackPopover = false
                    print("Feedback: Typo - \(self.questionID)")
                }

                Button("Verify") {
                    self.showFeedbackPopover = false
                    print("Feedback: Verify - \(self.questionID)")
                }
            }
            .padding()
            .frame(minWidth: 120)
        }
    }
}
