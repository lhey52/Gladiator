//
//  ReviewPrompt.swift
//  Gladiator
//

import SwiftUI
import StoreKit

/// Decides when to surface Apple's built-in "Rate this app" prompt.
///
/// The prompt is requested at most once, the first time either trigger fires:
///   • the user saves their first session, or
///   • 3 days have elapsed since they first opened the app.
///
/// Apple further rate-limits the actual dialog (it may not appear every time it
/// is requested, and never if the user already rated), so we record that we have
/// asked and never ask again.
enum ReviewPrompt {
    private static let firstOpenKey = "reviewFirstOpenDate"
    private static let didRequestKey = "reviewDidRequest"
    private static let daysBeforeTimePrompt: TimeInterval = 3 * 24 * 60 * 60

    private static var defaults: UserDefaults { .standard }

    private static var hasRequested: Bool {
        defaults.bool(forKey: didRequestKey)
    }

    /// Stamp the first-open date once, on the initial launch.
    static func recordFirstOpenIfNeeded(now: Date = .now) {
        guard defaults.object(forKey: firstOpenKey) == nil else { return }
        defaults.set(now, forKey: firstOpenKey)
    }

    /// True once 3+ days have passed since first open and we have never asked.
    static func isEligibleByTime(now: Date = .now) -> Bool {
        guard !hasRequested,
              let firstOpen = defaults.object(forKey: firstOpenKey) as? Date
        else { return false }
        return now.timeIntervalSince(firstOpen) >= daysBeforeTimePrompt
    }

    /// True if we have never asked — used immediately after the first session saves.
    static var isEligibleForFirstSession: Bool { !hasRequested }

    /// Fire the system prompt (if still eligible) and record that we asked.
    @MainActor
    static func request(_ action: RequestReviewAction) {
        guard !hasRequested else { return }
        defaults.set(true, forKey: didRequestKey)
        action()
    }
}
