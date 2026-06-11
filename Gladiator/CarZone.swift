//
//  CarZone.swift
//  Gladiator
//

import Foundation

enum CarZone: String, CaseIterable, Codable, Identifiable {
    // Raw values are stored on CustomField.zoneRaw. If a rawValue is renamed
    // once the app has shipped, add a legacy mapping in CustomField.zone so
    // existing rows still resolve (see the "Cockpit" -> .chassis example).
    // Unknown rawValues fall back to .general via `CarZone(rawValue:) ?? .general`.
    case flTire = "FL Tire"
    case frTire = "FR Tire"
    case rlTire = "RL Tire"
    case rrTire = "RR Tire"
    case engine = "Engine"
    case chassis = "Chassis"
    case general = "General"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .flTire: return "Front Left"
        case .frTire: return "Front Right"
        case .rlTire: return "Rear Left"
        case .rrTire: return "Rear Right"
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
        case .rlTire: return "RL "
        case .rrTire: return "RR "
        case .engine: return "Engine "
        case .chassis: return "Chassis "
        case .general: return ""
        }
    }

    static let pickerOrder: [CarZone] = [
        .flTire, .frTire, .rlTire, .rrTire,
        .engine, .chassis,
        .general
    ]

    static let carZones: [CarZone] = [
        .flTire, .frTire, .rlTire, .rrTire,
        .engine, .chassis
    ]
}
