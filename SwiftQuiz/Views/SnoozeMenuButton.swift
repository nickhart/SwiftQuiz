//
//  SnoozeMenuButton.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import SwiftUI

struct SnoozeMenuButton: View {
    @State private var showSnoozePopover = false

    var body: some View {
        Button(action: {
            self.showSnoozePopover = true
        }, label: {
            Image(systemName: "alarm")
        })
        .buttonStyle(.bordered)
        .popover(isPresented: self.$showSnoozePopover) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Snooze Options")
                    .font(.headline)
                    .padding(.bottom, 4)

                Button("1 hour") {
                    self.showSnoozePopover = false
                    // snooze 1 hour
                }

                Button("2 hours") {
                    self.showSnoozePopover = false
                    // snooze 2 hours
                }

                Button("4 hours") {
                    self.showSnoozePopover = false
                    // snooze 4 hours
                }

                Button("8 hours") {
                    self.showSnoozePopover = false
                    // snooze 8 hours
                }

                Button("1 day") {
                    self.showSnoozePopover = false
                    // snooze 24 hours
                }
            }
            .padding()
            .frame(minWidth: 120)
        }
    }
}
