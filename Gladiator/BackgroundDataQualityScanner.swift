//
//  BackgroundDataQualityScanner.swift
//  Gladiator
//

import Foundation

struct DataQualityResult: Identifiable, Sendable {
    let id = UUID()
    let trackName: String
    let vehicleName: String
    let fieldName: String
    let totalSessions: Int
    let missingCount: Int
    let missingPercent: Double
}

enum BackgroundDataQualityScanner {

    static let minimumSessions = 5

    private struct GroupKey: Hashable {
        let track: String
        let vehicle: String
    }

    static func scanAll(sessions: [SessionSnapshot], fields: [CustomFieldSnapshot]) -> [DataQualityResult] {
        guard !fields.isEmpty else { return [] }

        let grouped = Dictionary(grouping: sessions) { GroupKey(track: $0.trackName, vehicle: $0.vehicleName) }
        var results: [DataQualityResult] = []

        for (key, groupSessions) in grouped {
            guard !key.track.isEmpty else { continue }
            let total = groupSessions.count
            guard total >= minimumSessions else { continue }

            // Old code re-scanned every session's fieldValues for every
            // field via a `.contains { ... }.count` filter — O(sessions
            // × fields × fieldValues_per_session). With dict-backed
            // snapshots we drop straight to O(sessions × fields) using
            // a single dict lookup per (session, field).
            for field in fields {
                var recorded = 0
                for session in groupSessions {
                    if session.fieldValues[field.name]?.hasNonEmptyValue == true {
                        recorded += 1
                    }
                }
                let missing = total - recorded
                let missingPercent = Double(missing) / Double(total)
                results.append(DataQualityResult(
                    trackName: key.track,
                    vehicleName: key.vehicle,
                    fieldName: field.name,
                    totalSessions: total,
                    missingCount: missing,
                    missingPercent: missingPercent
                ))
            }
        }

        return results
    }
}
