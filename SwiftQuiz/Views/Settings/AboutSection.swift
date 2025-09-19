//
//  AboutSection.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct AboutSection: View {
    @EnvironmentObject private var settingsService: SettingsService

    var body: some View {
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

            if self.settingsService.aiProvider != .disabled {
                HStack {
                    Text("AI Provider")
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(self.settingsService.aiProvider.rawValue)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    Form {
        AboutSection()
    }
    .environmentObject(SettingsService.shared)
}
