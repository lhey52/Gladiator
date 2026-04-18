//
//  ComparisonEngine.swift
//  Gladiator
//

import Foundation

enum ComparisonMode: String, CaseIterable, Identifiable {
    case session = "Session vs Session"
    case year = "Year vs Year"
    case month = "Month vs Month"
    case custom = "Custom Range"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .session: return "SESSION"
        case .year: return "YEAR"
        case .month: return "MONTH"
        case .custom: return "CUSTOM"
        }
    }

    var icon: String {
        switch self {
        case .session: return "rectangle.on.rectangle"
        case .year: return "calendar"
        case .month: return "calendar.day.timeline.left"
        case .custom: return "calendar.badge.clock"
        }
    }
}

struct MetricComparison: Identifiable {
    let id: String
    let fieldName: String
    let fieldType: FieldType
    let valueA: Double?
    let valueB: Double?
    let higherIsBetter: Bool

    var winner: ComparisonWinner {
        guard let a = valueA, let b = valueB else {
            if valueA != nil { return .a }
            if valueB != nil { return .b }
            return .tie
        }
        if a == b { return .tie }
        if higherIsBetter {
            return a > b ? .a : .b
        }
        return a < b ? .a : .b
    }

    func displayValue(_ val: Double?) -> String {
        guard let val else { return "—" }
        if fieldType == .time {
            return TimeFormatting.secondsToDisplay(val)
        }
        if val == val.rounded() {
            return String(format: "%.0f", val)
        }
        return String(format: "%.2f", val)
    }
}

enum ComparisonWinner {
    case a, b, tie
}

enum ComparisonEngine {
    static func compareSessionValues(
        sessionA: Session,
        sessionB: Session,
        fields: [CustomField],
        higherIsBetterOverrides: [String: Bool]
    ) -> [MetricComparison] {
        fields.compactMap { field in
            let a = Double(sessionA.fieldValues.first(where: { $0.fieldName == field.name })?.value ?? "")
            let b = Double(sessionB.fieldValues.first(where: { $0.fieldName == field.name })?.value ?? "")
            guard a != nil || b != nil else { return nil }
            let hib = field.fieldType == .time ? false : (higherIsBetterOverrides[field.name] ?? true)
            return MetricComparison(
                id: field.name,
                fieldName: field.name,
                fieldType: field.fieldType,
                valueA: a,
                valueB: b,
                higherIsBetter: hib
            )
        }
    }

    static func comparePeriodAverages(
        sessionsA: [Session],
        sessionsB: [Session],
        fields: [CustomField],
        higherIsBetterOverrides: [String: Bool]
    ) -> [MetricComparison] {
        fields.compactMap { field in
            let a = average(sessions: sessionsA, fieldName: field.name)
            let b = average(sessions: sessionsB, fieldName: field.name)
            guard a != nil || b != nil else { return nil }
            let hib = field.fieldType == .time ? false : (higherIsBetterOverrides[field.name] ?? true)
            return MetricComparison(
                id: field.name,
                fieldName: field.name,
                fieldType: field.fieldType,
                valueA: a,
                valueB: b,
                higherIsBetter: hib
            )
        }
    }

    private static func average(sessions: [Session], fieldName: String) -> Double? {
        var sum = 0.0
        var count = 0
        for session in sessions {
            if let fv = session.fieldValues.first(where: { $0.fieldName == fieldName }),
               let val = Double(fv.value) {
                sum += val
                count += 1
            }
        }
        guard count > 0 else { return nil }
        return sum / Double(count)
    }
}
