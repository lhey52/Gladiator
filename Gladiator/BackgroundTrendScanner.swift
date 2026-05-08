//
//  BackgroundTrendScanner.swift
//  Gladiator
//

import Foundation

enum TrendClassification: Sendable {
    case improving
    case declining
    case stable
    case plateau
}

struct TrendScanResult: Identifiable, Sendable {
    let id = UUID()
    let trackName: String
    let vehicleName: String
    let fieldName: String
    let fieldType: FieldType
    let classification: TrendClassification
    let sessionCount: Int
}

enum BackgroundTrendScanner {

    static let minimumSessions = 5
    static let plateauMinSessions = 10
    static let slopeThreshold = 0.05

    private struct GroupKey: Hashable {
        let track: String
        let vehicle: String
    }

    static func scanAll(sessions: [SessionSnapshot], fields: [CustomFieldSnapshot]) -> [TrendScanResult] {
        let plottable = fields.filter(\.isPlottable)
        guard !plottable.isEmpty else { return [] }

        let grouped = Dictionary(grouping: sessions) { GroupKey(track: $0.trackName, vehicle: $0.vehicleName) }
        var results: [TrendScanResult] = []

        for (key, groupSessions) in grouped {
            guard !key.track.isEmpty else { continue }
            let sorted = groupSessions.sorted { $0.date < $1.date }

            for field in plottable {
                if let result = analyze(
                    trackName: key.track,
                    vehicleName: key.vehicle,
                    sessions: sorted,
                    fieldName: field.name,
                    fieldType: field.fieldType
                ) {
                    results.append(result)
                }
            }
        }

        return results
    }

    private static func analyze(trackName: String, vehicleName: String, sessions: [SessionSnapshot], fieldName: String, fieldType: FieldType) -> TrendScanResult? {
        let values: [Double] = sessions.compactMap { session in
            // O(1) dict lookup replacing session.fieldValues.first(where:).
            session.fieldValues[fieldName]?.doubleValue
        }
        guard values.count >= minimumSessions else { return nil }

        let window = min(minimumSessions, values.count)
        let recent = Array(values.suffix(window))
        let first = recent.first ?? 0
        let last = recent.last ?? 0

        guard first != 0 else {
            let classification: TrendClassification = values.count >= plateauMinSessions ? .plateau : .stable
            return TrendScanResult(
                trackName: trackName,
                vehicleName: vehicleName,
                fieldName: fieldName,
                fieldType: fieldType,
                classification: classification,
                sessionCount: values.count
            )
        }

        let change = (last - first) / abs(first)
        let isTime = fieldType == .time

        let classification: TrendClassification
        if abs(change) < slopeThreshold {
            classification = values.count >= plateauMinSessions ? .plateau : .stable
        } else if isTime {
            classification = change < 0 ? .improving : .declining
        } else {
            classification = change > 0 ? .improving : .declining
        }

        return TrendScanResult(
            trackName: trackName,
            vehicleName: vehicleName,
            fieldName: fieldName,
            fieldType: fieldType,
            classification: classification,
            sessionCount: values.count
        )
    }
}
