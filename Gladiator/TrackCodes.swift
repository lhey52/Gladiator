//
//  TrackCodes.swift
//  Gladiator
//

import Foundation

enum TrackCodeAction: Equatable {
    case grantPro
    case seedDemoData
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
        )
    ]

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

    // MARK: - Helpers

    private static func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components) ?? .distantFuture
    }
}
