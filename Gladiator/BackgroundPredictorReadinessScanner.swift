//
//  BackgroundPredictorReadinessScanner.swift
//  Gladiator
//

import Foundation

struct PredictorReadinessResult: Identifiable, Sendable {
    let id = UUID()
    let trackName: String
    let vehicleName: String
    let qualifyingSessionCount: Int
    let distinctMetricCount: Int
}

enum BackgroundPredictorReadinessScanner {

    static let minimumQualifyingSessions = 8
    static let minimumMetricsPerSession = 3

    private struct GroupKey: Hashable {
        let track: String
        let vehicle: String
    }

    static func scanAll(sessions: [SessionSnapshot], fields: [CustomFieldSnapshot]) -> [PredictorReadinessResult] {
        let plottable = fields.filter(\.isPlottable)
        guard plottable.count >= minimumMetricsPerSession else { return [] }

        // Built once outside the per-session hot loop: lets us check
        // "is this fieldName one of the plottable metrics?" in O(1)
        // while building the distinct-metrics Set, replacing the old
        // `plottable.contains(where:)` linear scan per fieldValue.
        let plottableNames = Set(plottable.map(\.name))
        let plottableNameOrder = plottable.map(\.name)

        let grouped = Dictionary(grouping: sessions) { GroupKey(track: $0.trackName, vehicle: $0.vehicleName) }
        var results: [PredictorReadinessResult] = []

        for (key, groupSessions) in grouped {
            guard !key.track.isEmpty else { continue }

            // Old: nested filter calling `session.fieldValues.contains
            // { fv in fv.fieldName == field.name && Double(fv.value)
            // != nil }` for every field for every session.
            // New: single O(1) dict lookup per (session, field) with
            // an early-out as soon as we hit minimumMetricsPerSession.
            let qualifyingSessions = groupSessions.filter { session in
                var recordedCount = 0
                for name in plottableNameOrder {
                    if let fv = session.fieldValues[name], fv.doubleValue != nil {
                        recordedCount += 1
                        if recordedCount >= minimumMetricsPerSession { return true }
                    }
                }
                return recordedCount >= minimumMetricsPerSession
            }

            let count = qualifyingSessions.count
            guard count >= minimumQualifyingSessions else { continue }

            // Single pass over qualifying sessions to build the
            // distinct-plottable-metric set; was previously two
            // separate iterations.
            var distinct = Set<String>()
            for session in qualifyingSessions {
                for (fieldName, fv) in session.fieldValues {
                    if plottableNames.contains(fieldName), fv.doubleValue != nil {
                        distinct.insert(fieldName)
                    }
                }
            }

            results.append(PredictorReadinessResult(
                trackName: key.track,
                vehicleName: key.vehicle,
                qualifyingSessionCount: count,
                distinctMetricCount: distinct.count
            ))
        }

        return results
    }
}
