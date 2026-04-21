//
//  BackgroundConsistencyScanner.swift
//  Gladiator
//

import Foundation

struct ConsistencyResult: Identifiable {
    let id = UUID()
    let trackName: String
    let vehicleName: String
    let fieldName: String
    let fieldType: FieldType
    let mean: Double
    let standardDeviation: Double
    let coefficientOfVariation: Double
    let sampleSize: Int
}

enum BackgroundConsistencyScanner {

    static let minimumSessions = 5

    private struct GroupKey: Hashable {
        let track: String
        let vehicle: String
    }

    static func scanAll(sessions: [Session], fields: [CustomField]) -> [ConsistencyResult] {
        let plottable = fields.filter { $0.fieldType.isPlottable }
        guard !plottable.isEmpty else { return [] }

        let grouped = Dictionary(grouping: sessions) { GroupKey(track: $0.trackName, vehicle: $0.vehicleName) }
        var results: [ConsistencyResult] = []

        for (key, groupSessions) in grouped {
            guard !key.track.isEmpty else { continue }
            for field in plottable {
                if let result = analyze(
                    trackName: key.track,
                    vehicleName: key.vehicle,
                    sessions: groupSessions,
                    fieldName: field.name,
                    fieldType: field.fieldType
                ) {
                    results.append(result)
                }
            }
        }

        return results
    }

    private static func analyze(
        trackName: String,
        vehicleName: String,
        sessions: [Session],
        fieldName: String,
        fieldType: FieldType
    ) -> ConsistencyResult? {
        let values: [Double] = sessions.compactMap { session in
            guard let fv = session.fieldValues.first(where: { $0.fieldName == fieldName }) else { return nil }
            return Double(fv.value)
        }

        guard values.count >= minimumSessions else { return nil }

        let n = Double(values.count)
        let mean = values.reduce(0, +) / n
        let absoluteMean = abs(mean)
        guard absoluteMean > 1e-12 else { return nil }

        let variance = values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / n
        let sd = sqrt(variance)
        let cov = sd / absoluteMean

        return ConsistencyResult(
            trackName: trackName,
            vehicleName: vehicleName,
            fieldName: fieldName,
            fieldType: fieldType,
            mean: mean,
            standardDeviation: sd,
            coefficientOfVariation: cov,
            sampleSize: values.count
        )
    }
}
