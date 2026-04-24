//
//  BestSubsetEngine.swift
//  Gladiator
//

import Foundation

// MARK: - Result types

struct RaceEngineerContributor: Identifiable {
    var id: String { name }
    let name: String
    let sharePercent: Double
    let standardizedCoefficient: Double
    let rawCoefficient: Double
    let observedMin: Double
    let observedMax: Double
    let observedMean: Double
    let observedStdDev: Double
    let topSessionMin: Double
    let topSessionMax: Double
    let topSessionCount: Int
    let unit: String
    let fieldType: FieldType

    // Direction is meaningful only if the standardized coefficient is not
    // effectively zero. A near-zero coefficient means the model found no
    // reliable sign for the predictor.
    var hasClearDirection: Bool {
        abs(standardizedCoefficient) > 1e-6
    }

    // Higher values associated with a "better" outcome depends on the outcome
    // field type; Race Engineer interprets sign in the view layer because it
    // needs both the outcome and predictor types.
    var isHigherBetter: Bool {
        standardizedCoefficient < 0
    }

    // Variation is "meaningful" when either the coefficient of variation
    // exceeds 2% or the absolute range is non-trivial. This guards against
    // fields that are essentially constant across all sessions, where a range
    // recommendation would be meaningless.
    var hasMeaningfulVariation: Bool {
        let absMean = abs(observedMean)
        let cov = absMean > 1e-9 ? observedStdDev / absMean : .infinity
        return cov > 0.02 || (observedMax - observedMin) > 1e-6
    }

    var topSessionsDiscriminate: Bool {
        guard topSessionCount > 0 else { return false }
        let total = observedMax - observedMin
        guard total > 1e-9 else { return false }
        let topRange = topSessionMax - topSessionMin
        // If the top sessions span more than 80% of the full range the range
        // itself provides no discriminating recommendation.
        return topRange / total < 0.8
    }
}

struct RaceEngineerResult {
    let outcome: String
    let outcomeUnit: String
    let outcomeFieldType: FieldType
    let predictors: [String]
    let adjustedRSquared: Double
    let contributors: [RaceEngineerContributor]
    let sampleSize: Int
    let dataSufficiency: DataSufficiencyLevel
    let tracks: [String]
    let vehicles: [String]
    let topSessionCount: Int
    let totalCandidates: Int
}

enum RaceEngineerOutcome {
    case success(RaceEngineerResult)
    case insufficientData(sampleSize: Int, minimumRequired: Int)
    case insufficientCandidates
    case noVariance
}

// MARK: - Engine

enum BestSubsetEngine {
    // Race Engineer is capped at 15 predictors to keep the subset search
    // tractable (2^15 − 1 = 32,767 subsets). Beyond that the search becomes
    // expensive and the data rarely supports that many predictors anyway.
    static let maxSubsetSize = 15
    static let minSessionsPerPredictor = RegressionEngine.sessionsPerPredictor

    static func analyze(
        sessions: [Session],
        outcome: String,
        outcomeFieldType: FieldType,
        candidatePredictors: [String],
        fieldTypes: [String: FieldType]
    ) -> RaceEngineerOutcome {
        guard !outcome.isEmpty else { return .insufficientCandidates }
        let candidates = candidatePredictors.filter { $0 != outcome }
        guard !candidates.isEmpty else { return .insufficientCandidates }

        let sessionsWithOutcome = sessions.filter { session in
            guard let fv = session.fieldValues.first(where: { $0.fieldName == outcome }),
                  Double(fv.value) != nil else { return false }
            return true
        }
        guard !sessionsWithOutcome.isEmpty else {
            return .insufficientData(sampleSize: 0, minimumRequired: minSessionsPerPredictor)
        }

        let maxBySessions = sessionsWithOutcome.count / minSessionsPerPredictor
        let searchCap = min(maxSubsetSize, candidates.count, maxBySessions)
        guard searchCap >= 1 else {
            return .insufficientData(
                sampleSize: sessionsWithOutcome.count,
                minimumRequired: minSessionsPerPredictor
            )
        }

        var best: (subset: [String], result: PredictiveAnalysisResult)?

        // Enumerate subsets by size, small → large. At each subset we delegate
        // the OLS math to RegressionEngine.analyze so both tools use identical
        // regression logic.
        for size in 1...searchCap {
            forEachSubset(of: candidates, size: size) { subset in
                let outcomeCase = RegressionEngine.analyze(
                    sessions: sessionsWithOutcome,
                    outcome: outcome,
                    predictors: subset
                )
                if case .success(let result) = outcomeCase {
                    if best == nil || result.adjustedRSquared > (best?.result.adjustedRSquared ?? -1) {
                        best = (subset, result)
                    }
                }
            }
        }

        guard let winner = best else {
            // If we never successfully fit any subset, fall back on whether
            // the outcome itself has variance — otherwise it's a data problem.
            let outcomeValues = sessionsWithOutcome.compactMap { session -> Double? in
                guard let fv = session.fieldValues.first(where: { $0.fieldName == outcome }) else { return nil }
                return Double(fv.value)
            }
            if let mean = outcomeValues.isEmpty ? nil : outcomeValues.reduce(0, +) / Double(outcomeValues.count) {
                let ss = outcomeValues.reduce(0) { $0 + ($1 - mean) * ($1 - mean) }
                if ss < 1e-12 { return .noVariance }
            }
            return .insufficientData(
                sampleSize: sessionsWithOutcome.count,
                minimumRequired: minSessionsPerPredictor
            )
        }

        let enriched = enrich(
            base: winner.result,
            outcome: outcome,
            outcomeFieldType: outcomeFieldType,
            predictorSubset: winner.subset,
            sessions: sessionsWithOutcome,
            fieldTypes: fieldTypes,
            totalCandidates: candidates.count
        )
        return .success(enriched)
    }

    // MARK: - Subset enumeration

    private static func forEachSubset(
        of elements: [String],
        size: Int,
        body: ([String]) -> Void
    ) {
        guard size > 0, size <= elements.count else { return }
        var indices = Array(0..<size)
        while true {
            var subset: [String] = []
            subset.reserveCapacity(size)
            for i in indices { subset.append(elements[i]) }
            body(subset)

            // Advance combination indices in lexicographic order.
            var i = size - 1
            while i >= 0 && indices[i] == elements.count - size + i {
                i -= 1
            }
            if i < 0 { break }
            indices[i] += 1
            for j in (i + 1)..<size {
                indices[j] = indices[j - 1] + 1
            }
        }
    }

    // MARK: - Post-fit enrichment

    private static func enrich(
        base: PredictiveAnalysisResult,
        outcome: String,
        outcomeFieldType: FieldType,
        predictorSubset: [String],
        sessions: [Session],
        fieldTypes: [String: FieldType],
        totalCandidates: Int
    ) -> RaceEngineerResult {
        let predictorOrder = predictorSubset

        var y: [Double] = []
        var X: [[Double]] = []
        y.reserveCapacity(sessions.count)
        X.reserveCapacity(sessions.count)

        for session in sessions {
            guard let yFV = session.fieldValues.first(where: { $0.fieldName == outcome }),
                  let yVal = Double(yFV.value) else { continue }
            var row: [Double] = []
            row.reserveCapacity(predictorOrder.count)
            var valid = true
            for p in predictorOrder {
                guard let fv = session.fieldValues.first(where: { $0.fieldName == p }),
                      let v = Double(fv.value) else { valid = false; break }
                row.append(v)
            }
            if valid {
                y.append(yVal)
                X.append(row)
            }
        }

        let n = y.count
        let k = predictorOrder.count

        // Per-predictor descriptive stats on the rows that contributed to the fit.
        var means = Array(repeating: 0.0, count: k)
        var stdDevs = Array(repeating: 0.0, count: k)
        var mins = Array(repeating: Double.infinity, count: k)
        var maxs = Array(repeating: -Double.infinity, count: k)

        for j in 0..<k {
            let col = X.map { $0[j] }
            let mean = col.reduce(0, +) / Double(max(n, 1))
            means[j] = mean
            let variance = col.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(max(n, 1))
            stdDevs[j] = sqrt(variance)
            mins[j] = col.min() ?? 0
            maxs[j] = col.max() ?? 0
        }

        // Outcome stats — needed to convert standardized coefficients back to
        // raw (un-standardized) coefficients for per-unit insights.
        let yMean = y.reduce(0, +) / Double(max(n, 1))
        let yVar = y.reduce(0) { $0 + ($1 - yMean) * ($1 - yMean) } / Double(max(n, 1))
        let ySd = sqrt(yVar)

        // Top-performing sessions: for Time outcomes lower is better, for
        // Number outcomes higher is better (matches Personal Bests convention).
        let topCount = max(3, min(10, n / 3))
        let sortedIndices: [Int] = (0..<n).sorted { a, b in
            switch outcomeFieldType {
            case .time: return y[a] < y[b]
            case .number: return y[a] > y[b]
            case .text: return y[a] > y[b] // unused — outcome is constrained to Number/Time
            }
        }
        let topIndices = Array(sortedIndices.prefix(topCount))

        // Contributions come back from RegressionEngine sorted by share — we
        // re-align them to the predictor order for stable lookup.
        let contributionByName: [String: PredictorContribution] = Dictionary(
            uniqueKeysWithValues: base.contributions.map { ($0.name, $0) }
        )

        var contributors: [RaceEngineerContributor] = []
        for (j, name) in predictorOrder.enumerated() {
            let contribution = contributionByName[name]
            let std = contribution?.standardizedCoefficient ?? 0
            let share = contribution?.sharePercent ?? 0
            let xSd = stdDevs[j]
            let rawCoef: Double = xSd > 1e-12 ? std * (ySd / xSd) : 0

            var topMin: Double = .infinity
            var topMax: Double = -.infinity
            for idx in topIndices {
                let v = X[idx][j]
                if v < topMin { topMin = v }
                if v > topMax { topMax = v }
            }
            if topIndices.isEmpty {
                topMin = mins[j]
                topMax = maxs[j]
            }

            contributors.append(RaceEngineerContributor(
                name: name,
                sharePercent: share,
                standardizedCoefficient: std,
                rawCoefficient: rawCoef,
                observedMin: mins[j],
                observedMax: maxs[j],
                observedMean: means[j],
                observedStdDev: stdDevs[j],
                topSessionMin: topMin,
                topSessionMax: topMax,
                topSessionCount: topIndices.count,
                unit: unit(for: name),
                fieldType: fieldTypes[name] ?? .number
            ))
        }
        contributors.sort { $0.sharePercent > $1.sharePercent }

        return RaceEngineerResult(
            outcome: outcome,
            outcomeUnit: unit(for: outcome),
            outcomeFieldType: outcomeFieldType,
            predictors: predictorOrder,
            adjustedRSquared: base.adjustedRSquared,
            contributors: contributors,
            sampleSize: base.sampleSize,
            dataSufficiency: base.dataSufficiency,
            tracks: base.tracks,
            vehicles: base.vehicles,
            topSessionCount: topIndices.count,
            totalCandidates: totalCandidates
        )
    }

    private static func unit(for combinedName: String) -> String {
        CustomField.split(name: combinedName).unit
    }
}
