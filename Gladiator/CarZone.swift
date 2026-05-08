//
//  CarZone.swift
//  Gladiator
//

import Foundation

enum CarZone: String, CaseIterable, Codable, Identifiable {
    // Raw values are stored on CustomField.zoneRaw so they need to stay
    // stable across renames. `.chassis` was previously named `.cockpit`
    // (rawValue "Cockpit"); CustomField.zone migrates legacy rows on
    // read so existing assignments survive the rename. Legacy "Front" /
    // "Rear" rawValues self-migrate to .general via the
    // `CarZone(rawValue:) ?? .general` fallback in CustomField.zone now
    // that those cases are gone.
    case flTire = "FL Tire"
    case frTire = "FR Tire"
    case blTire = "BL Tire"
    case brTire = "BR Tire"
    case engine = "Engine"
    case chassis = "Chassis"
    case general = "General"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .flTire: return "Front Left"
        case .frTire: return "Front Right"
        case .blTire: return "Back Left"
        case .brTire: return "Back Right"
        case .engine: return "Engine and Drivetrain"
        case .chassis: return "Chassis"
        case .general: return "General"
        }
    }

    // Prefix automatically prepended to a metric's stored name so the
    // zone is encoded into the name itself. Add Session / Edit Session
    // strip this back off when rendering inside the zone interface,
    // while history, analytics, and glossary all show the full prefixed
    // name. General has no prefix — its metrics flow through unchanged.
    var metricNamePrefix: String {
        switch self {
        case .flTire: return "FL "
        case .frTire: return "FR "
        case .blTire: return "RL "
        case .brTire: return "RR "
        case .engine: return "Engine "
        case .chassis: return "Chassis "
        case .general: return ""
        }
    }

    static let pickerOrder: [CarZone] = [
        .flTire, .frTire, .blTire, .brTire,
        .engine, .chassis,
        .general
    ]

    static let carZones: [CarZone] = [
        .flTire, .frTire, .blTire, .brTire,
        .engine, .chassis
    ]
}
