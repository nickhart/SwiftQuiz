//
//  BadgeCategoryFilter.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct BadgeCategoryFilter: View {
    @Binding var selectedCategory: BadgeCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(BadgeCategory.allCases, id: \.self) { category in
                    Button(action: {
                        self.selectedCategory = category
                    }, label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.caption)

                            Text(category.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            self.selectedCategory == category ?
                                Color.blue : Color(UIColor.secondarySystemBackground)
                        )
                        .foregroundColor(
                            self.selectedCategory == category ? .white : .primary
                        )
                        .cornerRadius(20)
                    })
                }
            }
            .padding(.horizontal)
        }
    }
}
