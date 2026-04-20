//
//  BackgroundCorrelationScanner.swift
//  Gladiator
//

import Foundation

struct CorrelationPairResult: Identifiable {
    let id = UUID()
    let trackName: String
    let fieldA: String
    let fieldB: String
    let r: Double
    let sampleSize: Int
}

enum BackgroundCorrelationScanner {

    static let minimumSessions = 5

    static func scanAll(sessions: [Session], fields: [CustomField]) -> [CorrelationPairResult] {
        let plottable = fields.filter { $0.fieldType.isPlottable }
        guard plottable.count >= 2 else { return [] }

        let byTrack = Dictionary(grouping: sessions) { $0.trackName }
        var results: [CorrelationPairResult] = []

        for (trackName, trackSessions) in byTrack {
            guard !trackName.isEmpty else { continue }
            for i in 0..<plottable.count {
                for j in (i + 1)..<plottable.count {
                    if let result = correlate(
                        trackName: trackName,
                        sessions: trackSessions,
                        fieldA: plottable[i].name,
                        fieldB: plottable[j].name
                    ) {
                        results.append(result)
                    }
                }
            }
        }

        return results
    }

    private static func correlate(trackName: String, sessions: [Session], fieldA: String, fieldB: String) -> CorrelationPairResult? {
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

        guard xs.count >= minimumSessions else { return nil }

        let r = pearson(xs, ys)
        let clamped = max(-1, min(1, r))
        return CorrelationPairResult(
            trackName: trackName,
            fieldA: fieldA,
            fieldB: fieldB,
            r: clamped,
            sampleSize: xs.count
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
