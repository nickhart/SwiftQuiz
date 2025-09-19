//
//  StudyStreakCard.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct StudyStreakCard: View {
    @State private var streak = StudyStreak(currentStreak: 7, longestStreak: 15, lastStudyDate: Date())
    @State private var showStreakAnimation = false

    var body: some View {
        VStack(spacing: 16) {
            // Header with flame icon and streak count
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.orange, .red]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                        .scaleEffect(self.showStreakAnimation ? 1.1 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: self.showStreakAnimation
                        )

                    Image(systemName: "flame.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(self.streak.currentStreak) Days")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Current Streak")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(self.streak.longestStreak)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)

                    Text("Best Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Streak visualization calendar
            StreakCalendarView(streak: self.streak)

            // Motivation message
            HStack {
                Image(systemName: self.streakMotivationIcon)
                    .foregroundColor(self.streakMotivationColor)
                    .font(.caption)

                Text(self.streakMotivationMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.systemBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .onAppear {
            self.showStreakAnimation = true
        }
    }

    private var streakMotivationMessage: String {
        switch self.streak.currentStreak {
        case 0:
            "Start your learning journey today!"
        case 1...2:
            "Great start! Keep the momentum going."
        case 3...6:
            "You're building a solid habit!"
        case 7...13:
            "Excellent consistency! You're on fire!"
        case 14...29:
            "Incredible dedication! You're unstoppable!"
        default:
            "Legendary streak! You're a true Swift expert!"
        }
    }

    private var streakMotivationIcon: String {
        switch self.streak.currentStreak {
        case 0:
            "play.circle.fill"
        case 1...6:
            "arrow.up.circle.fill"
        case 7...13:
            "flame.fill"
        case 14...29:
            "star.fill"
        default:
            "crown.fill"
        }
    }

    private var streakMotivationColor: Color {
        switch self.streak.currentStreak {
        case 0:
            .blue
        case 1...6:
            .green
        case 7...13:
            .orange
        case 14...29:
            .purple
        default:
            .yellow
        }
    }
}

#Preview {
    StudyStreakCard()
        .padding()
}
