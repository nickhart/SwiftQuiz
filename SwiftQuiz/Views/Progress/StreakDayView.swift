//
//  StreakDayView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct StreakDayView: View {
    let day: StreakDay

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(self.backgroundColor)
            .frame(width: 28, height: 28)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(self.borderColor, lineWidth: self.day.isToday ? 2 : 0)
            )
    }

    private var backgroundColor: Color {
        if self.day.hasActivity {
            Color.green.opacity(0.8)
        } else {
            Color(UIColor.tertiarySystemFill)
        }
    }

    private var borderColor: Color {
        self.day.isToday ? .blue : .clear
    }
}
