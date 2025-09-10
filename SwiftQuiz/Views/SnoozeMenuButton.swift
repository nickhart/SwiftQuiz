//
//  SnoozeMenuButton.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import SwiftUI

struct SnoozeMenuButton: View {
    var body: some View {
        Menu {
            Button("1 hour") { /* snooze 1 hour */ }
            Button("2 hours") { /* snooze 2 hours */ }
            Button("4 hours") { /* snooze 4 hours */ }
            Button("8 hours") { /* snooze 8 hours */ }
            Button("1 day") { /* snooze 24 hours */ }
        } label: {
            Image(systemName: "alarm")
        }
        .buttonStyle(.bordered)
    }
}
