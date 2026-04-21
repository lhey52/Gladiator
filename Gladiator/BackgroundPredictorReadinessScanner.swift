//
//  BackgroundPredictorReadinessScanner.swift
//  Gladiator
//

import Foundation

struct PredictorReadinessResult: Identifiable {
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

    static func scanAll(sessions: [Session], fields: [CustomField]) -> [PredictorReadinessResult] {
        let plottable = fields.filter { $0.fieldType.isPlottable }
        guard plottable.count >= minimumMetricsPerSession else { return [] }

        let grouped = Dictionary(grouping: sessions) { GroupKey(track: $0.trackName, vehicle: $0.vehicleName) }
        var results: [PredictorReadinessResult] = []

        for (key, groupSessions) in grouped {
            guard !key.track.isEmpty else { continue }

            let qualifyingSessions = groupSessions.filter { session in
                let recorded = plottable.filter { field in
                    session.fieldValues.contains { fv in
                        fv.fieldName == field.name && Double(fv.value) != nil
                    }
                }.count
                return recorded >= minimumMetricsPerSession
            }

            let count = qualifyingSessions.count
            guard count >= minimumQualifyingSessions else { continue }

            var distinct = Set<String>()
            for session in qualifyingSessions {
                for fv in session.fieldValues {
                    if plottable.contains(where: { $0.name == fv.fieldName }),
                       Double(fv.value) != nil {
                        distinct.insert(fv.fieldName)
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
