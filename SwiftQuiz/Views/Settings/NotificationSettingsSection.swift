//
//  NotificationSettingsSection.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct NotificationSettingsSection: View {
    @EnvironmentObject private var notificationService: NotificationService

    var body: some View {
        Section(header: Text("Daily Reminder")) {
            if self.notificationService.isAuthorized {
                Toggle("Enable Daily Reminder", isOn: Binding(
                    get: { self.notificationService.isReminderEnabled },
                    set: { self.notificationService.toggleReminder($0) }
                ))

                if self.notificationService.isReminderEnabled {
                    DatePicker(
                        "Reminder Time",
                        selection: Binding(
                            get: { self.notificationService.reminderTime },
                            set: { self.notificationService.setReminderTime($0) }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .padding(.vertical, 4)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notifications Not Authorized")
                        .foregroundColor(.secondary)

                    Button("Request Permission") {
                        Task {
                            await self.notificationService.requestPermission()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 8)
            }
        }
    }
}

#Preview {
    Form {
        NotificationSettingsSection()
    }
    .environmentObject(NotificationService.shared)
}
