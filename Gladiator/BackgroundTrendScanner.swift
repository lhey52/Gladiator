//
//  BackgroundTrendScanner.swift
//  Gladiator
//

import Foundation

enum TrendClassification {
    case improving
    case declining
    case stable
    case plateau
}

struct TrendScanResult: Identifiable {
    let id = UUID()
    let trackName: String
    let fieldName: String
    let fieldType: FieldType
    let classification: TrendClassification
    let sessionCount: Int
}

enum BackgroundTrendScanner {

    static let minimumSessions = 5
    static let plateauMinSessions = 10
    static let slopeThreshold = 0.05

    static func scanAll(sessions: [Session], fields: [CustomField]) -> [TrendScanResult] {
        let plottable = fields.filter { $0.fieldType.isPlottable }
        guard !plottable.isEmpty else { return [] }

        let byTrack = Dictionary(grouping: sessions) { $0.trackName }
        var results: [TrendScanResult] = []

        for (trackName, trackSessions) in byTrack {
            guard !trackName.isEmpty else { continue }
            let sorted = trackSessions.sorted { $0.date < $1.date }

            for field in plottable {
                if let result = analyze(
                    trackName: trackName,
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

    private static func analyze(trackName: String, sessions: [Session], fieldName: String, fieldType: FieldType) -> TrendScanResult? {
        let values: [Double] = sessions.compactMap { session in
            guard let fv = session.fieldValues.first(where: { $0.fieldName == fieldName }) else { return nil }
            return Double(fv.value)
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
            fieldName: fieldName,
            fieldType: fieldType,
            classification: classification,
            sessionCount: values.count
        )
    }
}
