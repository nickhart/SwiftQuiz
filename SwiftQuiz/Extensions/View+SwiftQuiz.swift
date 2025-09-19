//
//  View+SwiftQuiz.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

// MARK: - SwiftQuiz Navigation Types

/// SwiftQuiz-specific navigation bar display mode for cross-platform compatibility
enum SQNavigationBarDisplayMode {
    case automatic
    case inline
    case large
}

// MARK: - SwiftQuiz View Modifiers

extension View {
    /// Applies navigation bar title display mode (iOS only)
    /// - Parameter displayMode: The display mode for iOS navigation bars
    /// - Returns: The view with appropriate navigation styling for each platform
    func sqNavigationBarStyle(_ displayMode: SQNavigationBarDisplayMode = .automatic) -> some View {
        #if os(iOS)
            let iosDisplayMode: NavigationBarItem.TitleDisplayMode = switch displayMode {
            case .automatic:
                .automatic
            case .inline:
                .inline
            case .large:
                .large
            }
            return self.navigationBarTitleDisplayMode(iosDisplayMode)
        #else
            return self
        #endif
    }

    /// Hides the navigation bar (iOS only)
    /// - Parameter hidden: Whether to hide the navigation bar
    /// - Returns: The view with appropriate navigation bar visibility for each platform
    func sqNavigationBarHidden(_ hidden: Bool = true) -> some View {
        #if os(iOS)
            return self.navigationBarHidden(hidden)
        #else
            return self
        #endif
    }

    /// Applies SwiftQuiz-specific navigation styling
    /// - Parameters:
    ///   - title: The navigation title
    ///   - displayMode: The display mode (iOS only)
    /// - Returns: The view with appropriate navigation styling
    func sqNavigationTitle(_ title: String, displayMode: SQNavigationBarDisplayMode = .automatic) -> some View {
        self
            .navigationTitle(title)
            .sqNavigationBarStyle(displayMode)
    }

    /// Applies list styling appropriate for each platform
    /// - Returns: The view with appropriate list styling
    func sqListStyle() -> some View {
        #if os(iOS)
            return self.listStyle(PlainListStyle())
        #else
            return self.listStyle(InsetListStyle())
        #endif
    }

    /// Applies toolbar styling appropriate for each platform
    /// - Returns: The view with appropriate toolbar styling
    func sqToolbarStyle() -> some View {
        #if os(iOS)
            return self
        #else
            return self.toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    // macOS-specific toolbar items if needed
                }
            }
        #endif
    }

    /// Applies card-like styling with platform-appropriate shadows and backgrounds
    /// - Returns: The view styled as a card
    func sqCardStyle() -> some View {
        self
            .background(Color.systemBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    /// Applies grouped background styling
    /// - Returns: The view with grouped background styling
    func sqGroupedBackground() -> some View {
        self.background(Color.groupedBackground)
    }

    /// Applies item background styling (for list items, etc.)
    /// - Returns: The view with item background styling
    func sqItemBackground() -> some View {
        self.background(Color.itemBackground)
    }
}
