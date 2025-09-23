//
//  BadgeRarity.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import SwiftUI

enum BadgeRarity: String, Codable, CaseIterable {
    case common
    case uncommon
    case rare
    case epic
    case legendary

    var color: Color {
        switch self {
        case .common: .gray
        case .uncommon: .green
        case .rare: .blue
        case .epic: .purple
        case .legendary: .orange
        }
    }
}
