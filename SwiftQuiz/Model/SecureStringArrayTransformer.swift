//
//  SecureStringArrayTransformer.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/19/25.
//

import Foundation

/// Secure transformer for [String] arrays in Core Data
@objc(SecureStringArrayTransformer)
final class SecureStringArrayTransformer: NSSecureUnarchiveFromDataTransformer {
    static let name = NSValueTransformerName(rawValue: String(describing: SecureStringArrayTransformer.self))

    override static var allowedTopLevelClasses: [AnyClass] {
        [NSArray.self, NSString.self]
    }

    /// Registers the transformer with NSValueTransformer
    static func register() {
        let transformer = SecureStringArrayTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: self.name)
    }
}
