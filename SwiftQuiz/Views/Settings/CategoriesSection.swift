//
//  CategoriesSection.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct CategoriesSection: View {
    @EnvironmentObject private var settingsService: SettingsService

    var body: some View {
        Section(header: Text("Quiz Categories")) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Choose which categories to include in your quizzes:")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(self.settingsService.availableCategories, id: \.self) { category in
                Toggle(category, isOn: Binding(
                    get: { self.settingsService.isCategoryEnabled(category) },
                    set: { self.settingsService.toggleCategory(category, enabled: $0) }
                ))
            }

            if self.settingsService.enabledCategories.isEmpty {
                Text("At least one category must be enabled")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
}

#Preview {
    Form {
        CategoriesSection()
    }
    .environmentObject(SettingsService.shared)
}
