//
//  ClipboardService.swift
//  SwiftQuiz
//
//  Created by Nick Hart on 9/9/25.
//

import Foundation
#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

enum ClipboardService {
    static func copy(_ text: String) {
        #if os(iOS)
            UIPasteboard.general.string = text
        #elseif os(macOS)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
        #endif
    }
}
