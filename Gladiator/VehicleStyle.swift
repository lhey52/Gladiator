//
//  VehicleStyle.swift
//  Gladiator
//

import Foundation

// User-selectable race car silhouette style for the Add / Edit Session
// blueprint. The four tire zones, Chassis, and Engine sit at the same
// relative positions across all three styles — only the chassis outline
// changes — so existing zone interaction stays consistent regardless of
// which style is picked.
enum VehicleStyle: String, CaseIterable, Codable, Identifiable {
    case formula = "Formula"
    case lateModel = "Late Model"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var description: String {
        switch self {
        case .formula: return "F1-style open wheel"
        case .lateModel: return "Stock car / oval racing"
        }
    }

    static let storageKey = "vehicleStyle"
}
