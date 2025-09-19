//
//  CategoryStatItem.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct CategoryStatItem: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: self.icon)
                .foregroundColor(.blue)
                .font(.caption)

            Text(self.value)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(self.title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .background(Color.tertiarySystemBackground)
        .cornerRadius(8)
    }
}
