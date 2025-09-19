//
//  InsightFilterTabs.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

struct InsightFilterTabs: View {
    @Binding var selectedFilter: InsightFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(InsightFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        self.selectedFilter = filter
                    }, label: {
                        HStack(spacing: 6) {
                            Image(systemName: filter.icon)
                                .font(.caption)

                            Text(filter.displayName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            self.selectedFilter == filter ?
                                Color.blue : Color.secondarySystemBackground
                        )
                        .foregroundColor(
                            self.selectedFilter == filter ? .white : .primary
                        )
                        .cornerRadius(20)
                    })
                }
            }
            .padding(.horizontal)
        }
    }
}
