//
//  BackgroundDataQualityScanner.swift
//  Gladiator
//

import Foundation

struct DataQualityResult: Identifiable {
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

    static func scanAll(sessions: [Session], fields: [CustomField]) -> [DataQualityResult] {
        guard !fields.isEmpty else { return [] }

        let grouped = Dictionary(grouping: sessions) { GroupKey(track: $0.trackName, vehicle: $0.vehicleName) }
        var results: [DataQualityResult] = []

        for (key, groupSessions) in grouped {
            guard !key.track.isEmpty else { continue }
            let total = groupSessions.count
            guard total >= minimumSessions else { continue }

            for field in fields {
                let recorded = groupSessions.filter { session in
                    session.fieldValues.contains { fv in
                        fv.fieldName == field.name &&
                        !fv.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    }
                }.count
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
