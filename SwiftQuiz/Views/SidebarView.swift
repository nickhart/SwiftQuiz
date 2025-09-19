//
//  SidebarView.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/17/25.
//

import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var coordinator: NavigationCoordinator

    var body: some View {
        List(
            NavigationDestination.allCases,
            id: \.self,
            selection: self.$coordinator.selectedDestination
        ) { destination in
            NavigationLink(value: destination) {
                Label(destination.rawValue, systemImage: destination.systemImage)
            }
            .tag(destination)
        }
        .navigationTitle("Swift Quiz")
        .onAppear {
            if self.coordinator.selectedDestination == nil {
                self.coordinator.selectedDestination = .todaysQuiz
            }
        }
    }
}

#Preview {
    SidebarView()
        .environmentObject(NavigationCoordinator())
}
