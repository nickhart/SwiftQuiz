//
//  StreakCalendarView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct StreakCalendarView: View {
    let streak: StudyStreak
    @State private var weeks: [[StreakDay]] = []

    var body: some View {
        VStack(spacing: 4) {
            // Week day headers
            HStack(spacing: 4) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 20)
                }
            }

            // Calendar grid showing last 5 weeks
            ForEach(Array(self.weeks.enumerated()), id: \.offset) { _, week in
                HStack(spacing: 4) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                        StreakDayView(day: day)
                    }
                }
            }
        }
        .onAppear {
            self.generateStreakCalendar()
        }
    }

    private func generateStreakCalendar() {
        let calendar = Calendar.current
        let today = Date()

        // Generate last 35 days (5 weeks)
        var days: [StreakDay] = []

        for i in (0..<35).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
            let dayOfWeek = calendar.component(.weekday, from: date)
            let isToday = calendar.isDate(date, inSameDayAs: today)

            // Simulate study activity (for demo purposes)
            let hasActivity = Int.random(in: 1...10) > 3

            days.append(StreakDay(
                date: date,
                hasActivity: hasActivity,
                isToday: isToday,
                dayOfWeek: dayOfWeek
            ))
        }

        // Group into weeks
        self.weeks = days.chunked(into: 7)
    }
}
