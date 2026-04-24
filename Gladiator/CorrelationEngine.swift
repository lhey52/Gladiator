//
//  CorrelationEngine.swift
//  Gladiator
//

import SwiftUI

struct CorrelationResult {
    let fieldA: String
    let fieldB: String
    let r: Double
    let sampleSize: Int
    let strength: CorrelationStrength
    let dataSufficiency: DataSufficiencyLevel
    // Unique, non-empty track/vehicle names from the sessions that contributed to this calculation.
    // Used by the finding sentence to describe the sample's context.
    let tracks: [String]
    let vehicles: [String]

    // Three-part insight used by the Correlation Analysis view.

    var finding: String {
        let a = fieldA
        let b = fieldB
        let ctx = contextSuffix
        switch strength {
        case .veryStrongPositive:
            return "Higher \(a) shows a very strong positive correlation with \(b)\(ctx)."
        case .strongPositive:
            return "Higher \(a) shows a strong positive correlation with \(b)\(ctx)."
        case .moderatePositive:
            return "Higher \(a) shows a moderate positive correlation with \(b)\(ctx)."
        case .weakPositive:
            return "Higher \(a) shows a weak positive correlation with \(b)\(ctx)."
        case .none:
            return "\(a) shows no meaningful correlation with \(b)\(ctx)."
        case .weakNegative:
            return "Higher \(a) shows a weak negative correlation with \(b)\(ctx)."
        case .moderateNegative:
            return "Higher \(a) shows a moderate negative correlation with \(b)\(ctx)."
        case .strongNegative:
            return "Higher \(a) shows a strong negative correlation with \(b)\(ctx)."
        case .veryStrongNegative:
            return "Higher \(a) shows a very strong negative correlation with \(b)\(ctx)."
        }
    }

    var meaning: String {
        let a = fieldA
        let b = fieldB
        switch strength {
        case .veryStrongPositive:
            return "This means \(a) and \(b) move closely together in your data — as one increases the other consistently increases too."
        case .strongPositive:
            return "This suggests \(a) and \(b) tend to move together, though not perfectly consistently."
        case .moderatePositive:
            return "There is a moderate tendency for \(a) and \(b) to move in the same direction, but with notable exceptions."
        case .weakPositive:
            return "There is a slight tendency for these metrics to move together, but the relationship is inconsistent."
        case .none:
            return "These two metrics show no meaningful relationship in your data — changes in one do not appear to influence the other."
        case .weakNegative:
            return "There is a slight tendency for these metrics to move in opposite directions, but the relationship is inconsistent."
        case .moderateNegative:
            return "There is a moderate tendency for these metrics to move in opposite directions, though with notable exceptions."
        case .strongNegative:
            return "This suggests that as \(a) increases, \(b) tends to decrease, though not perfectly consistently."
        case .veryStrongNegative:
            return "This means as \(a) increases, \(b) consistently decreases in your data."
        }
    }

    var recommendation: String {
        let a = fieldA
        let b = fieldB
        switch strength {
        case .veryStrongPositive, .strongPositive, .veryStrongNegative, .strongNegative:
            return "This is a strong signal worth investigating — \(a) may have a meaningful influence on \(b) in your setup."
        case .moderatePositive, .moderateNegative:
            return "This relationship is worth monitoring as you log more sessions to see if it strengthens."
        case .weakPositive, .weakNegative:
            return "\(a) is unlikely to be a primary driver of \(b). Consider tracking other setup variables."
        case .none:
            return "Focus your analysis on other metric combinations that may show stronger relationships."
        }
    }

    private var contextSuffix: String {
        var text = " across \(sampleSize) session\(sampleSize == 1 ? "" : "s")"
        if tracks.count == 1, let track = tracks.first, !track.isEmpty {
            text += " at \(track)"
        }
        if vehicles.count == 1, let vehicle = vehicles.first, !vehicle.isEmpty {
            text += " in \(vehicle)"
        }
        return text
    }
}

enum CorrelationStrength {
    case veryStrongPositive
    case strongPositive
    case moderatePositive
    case weakPositive
    case none
    case weakNegative
    case moderateNegative
    case strongNegative
    case veryStrongNegative

    var label: String {
        switch self {
        case .veryStrongPositive: return "Very Strong Positive"
        case .strongPositive: return "Strong Positive"
        case .moderatePositive: return "Moderate Positive"
        case .weakPositive: return "Weak Positive"
        case .none: return "No Correlation"
        case .weakNegative: return "Weak Negative"
        case .moderateNegative: return "Moderate Negative"
        case .strongNegative: return "Strong Negative"
        case .veryStrongNegative: return "Very Strong Negative"
        }
    }

    var color: Color {
        switch self {
        case .veryStrongPositive: return Theme.accent
        case .strongPositive: return Theme.accent.opacity(0.85)
        case .moderatePositive: return Theme.accent.opacity(0.7)
        case .weakPositive: return Theme.textSecondary
        case .none: return Theme.textTertiary
        case .weakNegative: return Theme.textSecondary
        case .moderateNegative: return Color.red.opacity(0.7)
        case .strongNegative: return Color.red.opacity(0.85)
        case .veryStrongNegative: return Color.red
        }
    }

    static func from(r: Double) -> CorrelationStrength {
        switch r {
        case 0.7...1.0: return .veryStrongPositive
        case 0.5..<0.7: return .strongPositive
        case 0.3..<0.5: return .moderatePositive
        case 0.1..<0.3: return .weakPositive
        case -0.1..<0.1: return .none
        case -0.3 ..< -0.1: return .weakNegative
        case -0.5 ..< -0.3: return .moderateNegative
        case -0.7 ..< -0.5: return .strongNegative
        default: return r <= -0.7 ? .veryStrongNegative : .none
        }
    }
}

enum CorrelationEngine {
    // Aligned with Performance Predictor's Bad-tier floor (10 sessions).
    static let minimumSessions = 10

    static func calculate(sessions: [Session], fieldA: String, fieldB: String) -> CorrelationResult {
        var xs: [Double] = []
        var ys: [Double] = []
        var trackSet: Set<String> = []
        var vehicleSet: Set<String> = []

        for session in sessions {
            guard let aVal = session.fieldValues.first(where: { $0.fieldName == fieldA }),
                  let bVal = session.fieldValues.first(where: { $0.fieldName == fieldB }),
                  let x = Double(aVal.value),
                  let y = Double(bVal.value) else { continue }
            xs.append(x)
            ys.append(y)
            if !session.trackName.isEmpty { trackSet.insert(session.trackName) }
            if !session.vehicleName.isEmpty { vehicleSet.insert(session.vehicleName) }
        }

        let tracks = trackSet.sorted()
        let vehicles = vehicleSet.sorted()
        let n = xs.count
        guard n >= 2 else {
            return CorrelationResult(
                fieldA: fieldA, fieldB: fieldB, r: 0,
                sampleSize: n, strength: .none,
                dataSufficiency: DataSufficiencyLevel.from(sampleSize: n),
                tracks: tracks, vehicles: vehicles
            )
        }

        let r = pearson(xs, ys)
        let clamped = max(-1, min(1, r))
        return CorrelationResult(
            fieldA: fieldA,
            fieldB: fieldB,
            r: clamped,
            sampleSize: n,
            strength: CorrelationStrength.from(r: clamped),
            dataSufficiency: DataSufficiencyLevel.from(sampleSize: n),
            tracks: tracks,
            vehicles: vehicles
        )
    }

    private static func pearson(_ xs: [Double], _ ys: [Double]) -> Double {
        let n = Double(xs.count)
        let sumX = xs.reduce(0, +)
        let sumY = ys.reduce(0, +)
        let sumXY = zip(xs, ys).reduce(0) { $0 + $1.0 * $1.1 }
        let sumX2 = xs.reduce(0) { $0 + $1 * $1 }
        let sumY2 = ys.reduce(0) { $0 + $1 * $1 }

        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))
        guard denominator != 0 else { return 0 }
        return numerator / denominator
    }
}
