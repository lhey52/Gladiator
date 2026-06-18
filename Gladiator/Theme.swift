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

    // Race-car diagram blueprint tones. Scoped so bumping their visibility
    // doesn't leak into every other hairline-bordered surface in the app.
    static let chassisFillTop = Color.white.opacity(0.04)
    static let chassisFillBottom = Color.white.opacity(0.10)
    static let chassisLine = Color.white.opacity(0.14)

    // Flat fill for an active setup-zone box (a zone with metrics). Opaque so
    // every zone reads as the exact same shade regardless of where it sits on
    // the car-length blueprint gradient. ~#2E2E2E.
    static let zoneFill = Color(red: 0.181, green: 0.181, blue: 0.181)

    // Pit Box fill. Same intent as zoneFill, but the Pit Box sits on the plain
    // panel surface (Theme.surface) instead of the lighter blueprint gradient
    // the zones sit on. Identical gray looks lighter against a darker surround
    // (simultaneous contrast), so the Pit Box is nudged darker than zoneFill to
    // read as the SAME shade in context. Tune this if the two still don't match:
    // higher = lighter, lower = darker. Dialed-in offset: pitBoxFill ≈ zoneFill
    // minus ~0.02 (kept while bumping both brighter together).
    static let pitBoxFill = Color(red: 0.151, green: 0.151, blue: 0.151)
}

// Bracket-cornered panel styling shared across Race Engineer, Analytics, and
// Dashboard. Tweaking the bracket appearance (color, size, line weight,
// corner radius) globally only requires editing this one type.
enum PanelStyle {
    /// Bold accent brackets — reserved for full-screen tool hero panels.
    case hero
    /// Subdued accent brackets — for tile lists and dashboard cards.
    case tile

    var bracketColor: Color {
        switch self {
        case .hero: return Theme.accent.opacity(0.55)
        case .tile: return Theme.accent.opacity(0.35)
        }
    }

    var bracketSize: CGFloat {
        switch self {
        case .hero: return 12
        case .tile: return 10
        }
    }

    var bracketLineWidth: CGFloat {
        switch self {
        case .hero: return 1.4
        case .tile: return 1.2
        }
    }
}

extension View {
    /// Wraps the receiver in the standard engineering panel chrome:
    /// squared surface fill, hairline border, and L-shaped bracket corners.
    /// Pass `.hero` for primary tool surfaces, `.tile` for list cards.
    func bracketPanel(_ style: PanelStyle = .tile, cornerRadius: CGFloat = 4) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
            .overlay(
                BracketCorners(
                    color: style.bracketColor,
                    size: style.bracketSize,
                    lineWidth: style.bracketLineWidth
                )
            )
    }

    /// Same squared surface + hairline border as `bracketPanel`, but
    /// without the L-shaped accent corners. Use when the panel should
    /// belong visually to the engineering panel family but stay quieter
    /// than the bracket-cornered variants (e.g., the dashboard).
    func squarePanel(cornerRadius: CGFloat = 4) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
    }
}
