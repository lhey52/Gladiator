//
//  CorrelationEngine.swift
//  Gladiator
//

import SwiftUI

enum CorrelationConfidence {
    case low
    case moderate
    case high

    var label: String {
        switch self {
        case .low: return "Low Confidence"
        case .moderate: return "Moderate Confidence"
        case .high: return "High Confidence"
        }
    }

    var color: Color {
        switch self {
        case .low: return Theme.textSecondary
        case .moderate: return Theme.accent.opacity(0.7)
        case .high: return Theme.accent
        }
    }

    var systemImage: String {
        switch self {
        case .low: return "shield.lefthalf.filled"
        case .moderate: return "shield.checkered"
        case .high: return "shield.fill"
        }
    }

    static func from(sampleSize: Int) -> CorrelationConfidence {
        switch sampleSize {
        case 31...: return .high
        case 11...30: return .moderate
        default: return .low
        }
    }
}

struct CorrelationResult {
    let fieldA: String
    let fieldB: String
    let r: Double
    let sampleSize: Int
    let strength: CorrelationStrength
    let confidence: CorrelationConfidence

    var insight: String {
        let a = fieldA
        let b = fieldB
        let prefix = "Based on \(sampleSize) sessions (\(confidence.label)), "
        let suffix: String
        switch confidence {
        case .low: suffix = " Record more sessions to improve accuracy."
        case .moderate: suffix = ""
        case .high: suffix = ""
        }

        let core: String
        switch strength {
        case .veryStrongPositive:
            core = "higher values of \(a) show a very strong correlation with higher values of \(b)."
        case .strongPositive:
            core = "higher values of \(a) show a strong correlation with higher values of \(b)."
        case .moderatePositive:
            core = "higher values of \(a) show a moderate correlation with higher values of \(b)."
        case .weakPositive:
            core = "higher values of \(a) show a weak correlation with higher values of \(b)."
        case .none:
            core = "no meaningful pattern was identified between \(a) and \(b)."
        case .weakNegative:
            core = "higher values of \(a) show a weak correlation with lower values of \(b)."
        case .moderateNegative:
            core = "higher values of \(a) show a moderate correlation with lower values of \(b)."
        case .strongNegative:
            core = "higher values of \(a) show a strong correlation with lower values of \(b)."
        case .veryStrongNegative:
            core = "higher values of \(a) show a very strong correlation with lower values of \(b)."
        }
        return prefix + core + suffix
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
    static let minimumSessions = 5

    static func calculate(sessions: [Session], fieldA: String, fieldB: String) -> CorrelationResult {
        var xs: [Double] = []
        var ys: [Double] = []

        for session in sessions {
            guard let aVal = session.fieldValues.first(where: { $0.fieldName == fieldA }),
                  let bVal = session.fieldValues.first(where: { $0.fieldName == fieldB }),
                  let x = Double(aVal.value),
                  let y = Double(bVal.value) else { continue }
            xs.append(x)
            ys.append(y)
        }

        let n = xs.count
        guard n >= 2 else {
            return CorrelationResult(
                fieldA: fieldA, fieldB: fieldB, r: 0,
                sampleSize: n, strength: .none,
                confidence: .low
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
            confidence: CorrelationConfidence.from(sampleSize: n)
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
