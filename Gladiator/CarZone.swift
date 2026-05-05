//
//  CarZone.swift
//  Gladiator
//

import Foundation

enum CarZone: String, CaseIterable, Codable, Identifiable {
    // Raw values are kept as-is for SwiftData storage compatibility — existing
    // CustomField.zoneRaw rows persist their original strings. User-facing
    // labels are surfaced via displayName below so they can evolve without
    // breaking persistence.
    case flTire = "FL Tire"
    case frTire = "FR Tire"
    case blTire = "BL Tire"
    case brTire = "BR Tire"
    case engine = "Engine"
    case cockpit = "Cockpit"
    case front = "Front"
    case rear = "Rear"
    case general = "General"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .flTire: return "Front Left Tire"
        case .frTire: return "Front Right Tire"
        case .blTire: return "Rear Left Tire"
        case .brTire: return "Rear Right Tire"
        case .engine: return "Engine"
        case .cockpit: return "Cockpit"
        case .front: return "Front Wing"
        case .rear: return "Rear Wing"
        case .general: return "General"
        }
    }

    static let pickerOrder: [CarZone] = [
        .flTire, .frTire, .blTire, .brTire,
        .engine, .cockpit, .front, .rear,
        .general
    ]

    static let carZones: [CarZone] = [
        .flTire, .frTire, .blTire, .brTire,
        .engine, .cockpit, .front, .rear
    ]
}
