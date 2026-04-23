//
//  Theme.swift
//  Gladiator
//

import SwiftUI

enum Theme {
    static let background = Color(red: 0.039, green: 0.039, blue: 0.039) // #0A0A0A
    static let surface = Color(red: 0.102, green: 0.102, blue: 0.102)    // #1A1A1A
    static let surfaceElevated = Color(red: 0.14, green: 0.14, blue: 0.14)
    static let accent = Color(red: 1.0, green: 0.42, blue: 0.0)          // #FF6B00
    static let success = Color(red: 0.24, green: 0.8, blue: 0.49)        // status-ok green
    static let warning = Color(red: 1.0, green: 0.78, blue: 0.23)        // caution yellow
    static let danger = Color(red: 0.95, green: 0.28, blue: 0.28)        // alert red
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.35)
    static let hairline = Color.white.opacity(0.08)
}
