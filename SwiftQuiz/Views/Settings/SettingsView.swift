//
//  SettingsView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/14/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                AIAssistantSection()

                #if DEBUG
                    DebugSettingsSection()
                #endif

                NotificationSettingsSection()

                CategoriesSection()

                HelpSupportSection()

                AboutSection()
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(NotificationService.shared)
        .environmentObject(SettingsService.shared)
        .environmentObject(AIService.shared)
}
