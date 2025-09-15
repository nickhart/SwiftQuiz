//
//  SettingsView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/14/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var notificationService: NotificationService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
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
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notifications Not Authorized")
                                .foregroundColor(.secondary)

                            Button("Request Permission") {
                                Task {
                                    await self.notificationService.requestPermission()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }

                Section(header: Text("About")) {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Questions")
                        Spacer()
                        Text("200 Swift Questions")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button("Done") {
                            self.dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(NotificationService.shared)
}
