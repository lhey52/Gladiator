//
//  TrackCodes.swift
//  Gladiator
//

import Foundation

enum TrackCodeAction: Equatable {
    case grantPro
    case seedDemoData
    case unlockAdminConsole

    var isPersistent: Bool {
        switch self {
        case .grantPro, .unlockAdminConsole: return true
        case .seedDemoData: return false
        }
    }
}

struct TrackCodeEntry {
    let code: String
    let action: TrackCodeAction
    let expiryDate: Date
    let isActive: Bool
}

enum TrackCodes {

    // MARK: - Code definitions (edit here to add new codes)

    static let allCodes: [TrackCodeEntry] = [
        TrackCodeEntry(
            code: "VIPACCESS",
            action: .grantPro,
            expiryDate: makeDate(year: 2026, month: 7, day: 1),
            isActive: true
        ),
        TrackCodeEntry(
            code: "GLADIATORDEMO",
            action: .seedDemoData,
            expiryDate: makeDate(year: 2026, month: 7, day: 1),
            isActive: true
        ),
        TrackCodeEntry(
            code: "GLADIATORDEBUG5269",
            action: .unlockAdminConsole,
            // Admin console is intentionally disabled for public release via a
            // past expiry, so the unlock action can never fire. To re-enable
            // for internal debugging, bump this to a future date.
            expiryDate: makeDate(year: 2020, month: 1, day: 1),
            isActive: true
        )
    ]

    // MARK: - Lookup

    static func action(for code: String) -> TrackCodeAction? {
        let normalized = code.trimmingCharacters(in: .whitespaces).uppercased()
        return allCodes.first { $0.code == normalized }?.action
    }

    // MARK: - Validation

    enum ValidationResult {
        case success(TrackCodeAction)
        case invalid
        case expired
    }

    static func validate(_ input: String) -> ValidationResult {
        let normalized = input.trimmingCharacters(in: .whitespaces).uppercased()
        guard let entry = allCodes.first(where: { $0.code == normalized && $0.isActive }) else {
            return .invalid
        }
        if Date.now > entry.expiryDate {
            return .expired
        }
        return .success(entry.action)
    }

    // MARK: - Launch revocation

    /// Call once at app launch. If the currently-active persistent code (a Pro
    /// grant or admin-console unlock) has since expired or is no longer
    /// recognized, this reverses its grant and clears the active code — so a
    /// grant can never outlive its code's expiry. Only one code is active at a
    /// time, so this covers any/all codes present.
    @MainActor
    static func revokeActiveCodeIfExpired() {
        let defaults = UserDefaults.standard
        let activeCode = (defaults.string(forKey: "activeTrackCode") ?? "")
            .trimmingCharacters(in: .whitespaces)

        // What does a currently-VALID (active + unexpired) code grant, if any?
        var validAction: TrackCodeAction?
        if !activeCode.isEmpty, case .success(let granted) = validate(activeCode) {
            validAction = granted
        } else if !activeCode.isEmpty {
            // Active code present but expired / no longer recognized — clear it.
            defaults.set("", forKey: "activeTrackCode")
        }

        // The admin console stays unlocked only while backed by a valid code.
        let adminUnlocked = (validAction == .unlockAdminConsole)
        if !adminUnlocked {
            defaults.set(false, forKey: "isAdminConsoleUnlocked")
        }

        // Code-granted Pro survives only while backed by a valid Pro code, or
        // while the admin console is still unlocked (so its override toggle
        // keeps working in there). Otherwise revoke it — this also clears Pro
        // left toggled on via the admin console once the console is locked.
        if validAction != .grantPro && !adminUnlocked {
            IAPManager.shared.codeGrantedPro = false
        }
    }

    // MARK: - Helpers

    private static func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? .distantFuture
    }
}
