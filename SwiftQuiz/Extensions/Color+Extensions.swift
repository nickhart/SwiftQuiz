//
//  Color+Extensions.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

#if canImport(AppKit)
    import AppKit
#endif

extension Color {
    // MARK: - System Background Colors

    /// Primary system background color that adapts to light/dark mode
    static let systemBackground: Color = {
        #if canImport(UIKit)
            return Color(UIColor.systemBackground)
        #elseif canImport(AppKit)
            return Color(NSColor.windowBackgroundColor)
        #else
            return Color.white
        #endif
    }()

    /// Secondary system background color for grouped content
    static let secondarySystemBackground: Color = {
        #if canImport(UIKit)
            return Color(UIColor.secondarySystemBackground)
        #elseif canImport(AppKit)
            return Color(NSColor.controlBackgroundColor)
        #else
            return Color(white: 0.95)
        #endif
    }()

    /// Tertiary system background color for elevated content
    static let tertiarySystemBackground: Color = {
        #if canImport(UIKit)
            return Color(UIColor.tertiarySystemBackground)
        #elseif canImport(AppKit)
            return Color(NSColor.unemphasizedSelectedContentBackgroundColor)
        #else
            return Color(white: 0.92)
        #endif
    }()

    /// Tertiary system fill color for subtle backgrounds
    static let tertiarySystemFill: Color = {
        #if canImport(UIKit)
            return Color(UIColor.tertiarySystemFill)
        #elseif canImport(AppKit)
            return Color(NSColor.tertiarySystemFill)
        #else
            return Color(white: 0.88)
        #endif
    }()

    /// System gray level 5 for subtle dividers and backgrounds
    static let systemGray5: Color = {
        #if canImport(UIKit)
            return Color(UIColor.systemGray5)
        #elseif canImport(AppKit)
            return Color(NSColor.systemGray)
        #else
            return Color(white: 0.9)
        #endif
    }()

    /// System gray level 6 for very subtle backgrounds
    static let systemGray6: Color = {
        #if canImport(UIKit)
            return Color(UIColor.systemGray6)
        #elseif canImport(AppKit)
            return Color(NSColor.controlColor)
        #else
            return Color(white: 0.95)
        #endif
    }()

    // MARK: - Semantic App Colors

    /// Background color for cards and content containers
    static let cardBackground = systemBackground

    /// Background color for grouped content areas
    static let groupedBackground = secondarySystemBackground

    /// Background color for individual items within groups
    static let itemBackground = tertiarySystemBackground

    /// Background color for statistical items and data display
    static let statBackground = secondarySystemBackground

    /// Subtle fill color for inactive or secondary elements
    static let subtleFill = tertiarySystemFill
}
