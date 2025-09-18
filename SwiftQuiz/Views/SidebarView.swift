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
        List(selection: self.$coordinator.selectedDestination) {
            ForEach(NavigationDestination.allCases, id: \.self) { destination in
                NavigationLink(value: destination) {
                    Label(destination.rawValue, systemImage: destination.systemImage)
                }
            }
        }
        .navigationTitle("Swift Quiz")
    }
}

#Preview {
    SidebarView()
        .environmentObject(NavigationCoordinator())
}
