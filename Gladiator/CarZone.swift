//
//  CarZone.swift
//  Gladiator
//

import Foundation

enum CarZone: String, CaseIterable, Codable, Identifiable {
    // Raw values are kept as-is for SwiftData storage compatibility — existing
    // CustomField.zoneRaw rows persist their original strings. User-facing
    // labels are surfaced via displayName below so they can evolve without
    // breaking persistence. Legacy "Front" / "Rear" rawValues self-migrate
    // to .general via the `CarZone(rawValue:) ?? .general` fallback in
    // CustomField.zone now that those cases are gone.
    case flTire = "FL Tire"
    case frTire = "FR Tire"
    case blTire = "BL Tire"
    case brTire = "BR Tire"
    case engine = "Engine"
    case cockpit = "Cockpit"
    case general = "General"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .flTire: return "Front Left"
        case .frTire: return "Front Right"
        case .blTire: return "Back Left"
        case .brTire: return "Back Right"
        case .engine: return "Engine and Drivetrain"
        case .cockpit: return "Cockpit"
        case .general: return "General"
        }
    }

    static let pickerOrder: [CarZone] = [
        .flTire, .frTire, .blTire, .brTire,
        .engine, .cockpit,
        .general
    ]

    static let carZones: [CarZone] = [
        .flTire, .frTire, .blTire, .brTire,
        .engine, .cockpit
    ]
}
