//
//  DebugSettingsSection.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

#if DEBUG
    struct DebugSettingsSection: View {
        @EnvironmentObject private var settingsService: SettingsService

        var body: some View {
            Section(header: Text("Debug Settings")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Development Settings")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("These settings are only available in debug builds to help during development.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)

                Button(action: {
                    KeychainManager.shared.nukeAllSwiftQuizEntries()
                }, label: { Label("Nuke Keychain", systemImage: "trash") })
                    .foregroundColor(.red)
                Toggle("Enable Debug Mode", isOn: Binding(
                    get: { self.settingsService.isDebugModeEnabled },
                    set: { newValue in
                        self.settingsService.isDebugModeEnabled = newValue
                    }
                ))

                if self.settingsService.isDebugModeEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Evaluation Mode")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("Evaluation Mode", selection: Binding(
                            get: { self.settingsService.debugEvaluationMode },
                            set: { newValue in
                                self.settingsService.debugEvaluationMode = newValue
                            }
                        )) {
                            ForEach(DebugEvaluationMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)

                        Text(
                            """
                            Controls how quiz answers are evaluated.
                            'Use AI' uses actual API calls, while other modes save tokens during development.
                            """
                        )
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    #Preview {
        Form {
            DebugSettingsSection()
        }
        .environmentObject(SettingsService.shared)
    }
#endif
