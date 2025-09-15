//
//  NotificationService.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/14/25.
//

import Foundation
import UserNotifications

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false
    @Published var reminderTime = Date()
    @Published var isReminderEnabled = false

    private let userDefaults = UserDefaults.standard
    private let reminderTimeKey = "dailyReminderTime"
    private let reminderEnabledKey = "isDailyReminderEnabled"
    private let notificationIdentifier = "dailyQuizReminder"

    private init() {
        self.loadSettings()
    }

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            self.isAuthorized = granted

            if granted, self.isReminderEnabled {
                await self.scheduleDailyReminder()
            }
        } catch {
            print("Failed to request notification permission: \(error)")
            self.isAuthorized = false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        self.isAuthorized = settings.authorizationStatus == .authorized
    }

    func setReminderTime(_ time: Date) {
        self.reminderTime = time
        self.saveSettings()

        if self.isAuthorized, self.isReminderEnabled {
            Task {
                await self.scheduleDailyReminder()
            }
        }
    }

    func toggleReminder(_ enabled: Bool) {
        self.isReminderEnabled = enabled
        self.saveSettings()

        if enabled, self.isAuthorized {
            Task {
                await self.scheduleDailyReminder()
            }
        } else {
            self.cancelDailyReminder()
        }
    }

    private func scheduleDailyReminder() async {
        // Cancel existing notification
        self.cancelDailyReminder()

        guard self.isAuthorized, self.isReminderEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Daily Swift Quiz"
        content.body = "Time for your daily Swift knowledge check! 🧠"
        content.sound = .default
        content.badge = 1
        content.userInfo = ["action": "openQuiz"]

        // Create date components from reminderTime
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: self.reminderTime)

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Daily reminder scheduled for \(self.formatTime(self.reminderTime))")
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }

    private func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [self.notificationIdentifier]
        )
        print("Daily reminder cancelled")
    }

    private func loadSettings() {
        // Load reminder time (default to 9:00 AM)
        if let timeData = userDefaults.data(forKey: reminderTimeKey),
           let time = try? JSONDecoder().decode(Date.self, from: timeData) {
            self.reminderTime = time
        } else {
            // Default to 9:00 AM
            let calendar = Calendar.current
            let components = DateComponents(hour: 9, minute: 0)
            self.reminderTime = calendar.date(from: components) ?? Date()
        }

        // Load reminder enabled state
        self.isReminderEnabled = self.userDefaults.bool(forKey: self.reminderEnabledKey)
    }

    private func saveSettings() {
        // Save reminder time
        if let timeData = try? JSONEncoder().encode(reminderTime) {
            self.userDefaults.set(timeData, forKey: self.reminderTimeKey)
        }

        // Save reminder enabled state
        self.userDefaults.set(self.isReminderEnabled, forKey: self.reminderEnabledKey)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func handleNotificationResponse(_ response: UNNotificationResponse) -> Bool {
        guard response.notification.request.identifier == self.notificationIdentifier else {
            return false
        }

        if let action = response.notification.request.content.userInfo["action"] as? String,
           action == "openQuiz" {
            // Notification was tapped - app should open to quiz
            return true
        }

        return false
    }
}
