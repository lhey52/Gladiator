//
//  RegressionEngine.swift
//  Gladiator
//

import Foundation

struct PredictorContribution: Identifiable {
    var id: String { name }
    let name: String
    let standardizedCoefficient: Double
    let sharePercent: Double
}

struct PredictiveAnalysisResult {
    let outcome: String
    let predictors: [String]
    let adjustedRSquared: Double
    let contributions: [PredictorContribution]
    let sampleSize: Int
    let dataSufficiency: DataSufficiencyLevel
    // Unique, non-empty track/vehicle names from the sessions that contributed to this calculation.
    // Used by the finding sentence to describe the sample's context.
    let tracks: [String]
    let vehicles: [String]

    var powerLevel: PredictivePowerLevel {
        PredictivePowerLevel.from(adjustedRSquared: adjustedRSquared)
    }

    // Three-part insight used by the Performance Predictor results card.

    var finding: String {
        let pct = Int((adjustedRSquared * 100).rounded())
        let sessionPhrase = "across \(sampleSize) session\(sampleSize == 1 ? "" : "s")\(contextSuffix)"
        if predictors.count == 1, let top = contributions.first {
            return "\(top.name) explains \(pct)% of the variation in \(outcome) \(sessionPhrase)."
        }
        if let top = contributions.first {
            let topShare = Int(top.sharePercent.rounded())
            return "Your predictors explain \(pct)% of the variation in \(outcome) \(sessionPhrase), with \(top.name) contributing the largest share at \(topShare)%."
        }
        return "Your predictors explain \(pct)% of the variation in \(outcome) \(sessionPhrase)."
    }

    var meaning: String {
        switch powerLevel {
        case .veryStrong:
            return "This means your predictors capture nearly all of what drives \(outcome) in your data — very little variation comes from factors outside the model."
        case .strong:
            return "This suggests your predictors explain most of what drives \(outcome), though some variation still comes from factors outside the model."
        case .good:
            return "There is a meaningful share of \(outcome) explained by your predictors, but a notable portion still comes from factors outside the model."
        case .moderate:
            return "There is a moderate share of \(outcome) explained by your predictors, though most variation comes from factors outside the model."
        case .weak:
            return "There is only a slight link between these predictors and \(outcome) — most of what drives it lies outside the model."
        }
    }

    var recommendation: String {
        let topName = contributions.first?.name ?? "your top predictor"
        let hasMultiple = predictors.count > 1

        switch powerLevel {
        case .veryStrong, .strong:
            if hasMultiple {
                return "This is a strong signal worth acting on — \(topName) and your other leading predictors likely have a meaningful influence on \(outcome) in your setup."
            } else {
                return "This is a strong signal worth acting on — \(topName) likely has a meaningful influence on \(outcome) in your setup."
            }
        case .good:
            return "This model is worth building on — \(topName) is a key driver, but track additional setup variables to capture more of what shapes \(outcome)."
        case .moderate:
            return "This model is worth monitoring as you log more sessions to see if it strengthens — consider adding or swapping predictors to capture more of what drives \(outcome)."
        case .weak:
            if hasMultiple {
                return "These predictors are unlikely to be primary drivers of \(outcome). Consider tracking other setup variables."
            } else {
                return "\(topName) is unlikely to be a primary driver of \(outcome). Consider tracking other setup variables."
            }
        }
    }

    private var contextSuffix: String {
        var text = ""
        if tracks.count == 1, let track = tracks.first, !track.isEmpty {
            text += " at \(track)"
        }
        if vehicles.count == 1, let vehicle = vehicles.first, !vehicle.isEmpty {
            text += " in \(vehicle)"
        }
        return text
    }
}

enum DataSufficiencyLevel {
    case bad
    case poor
    case fair
    case good
    case excellent

    var levelName: String {
        switch self {
        case .bad: return "Bad"
        case .poor: return "Poor"
        case .fair: return "Fair"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }

    // predictorCount defaults to 1 so callers without a predictor concept (e.g. Correlation Analysis,
    // which has a single paired relationship) can pass only the sample size.
    func description(sampleSize: Int, predictorCount: Int = 1) -> String {
        let base: String
        switch self {
        case .bad:
            base = "Your session count just meets the minimum requirement but results at this level are unlikely to be reliable. There is very little data to work with and a few unusual sessions could significantly skew the result. Add more sessions before drawing any conclusions from this analysis."
        case .poor:
            base = "You have a limited amount of data for this analysis. The result gives an early indication of a potential relationship but should not be acted on yet. More sessions will significantly improve the reliability of this result."
        case .fair:
            base = "A reasonable foundation of data to work with. The result is worth noting but continue logging sessions to strengthen it. At this level the result is directionally useful but may shift as more data is added."
        case .good:
            base = "Your session count provides a solid foundation for this analysis. The result is reliable and you can begin drawing meaningful conclusions. Continue logging to move towards Excellent."
        case .excellent:
            base = "Your data meets the ideal threshold. This result is excellently supported and you can act on it with confidence. This level of data is rare and reflects consistent long term logging."
        }
        if let appendix = nextTargetSentence(sampleSize: sampleSize, predictorCount: predictorCount) {
            return "\(base) \(appendix)"
        }
        return base
    }

    // Below Good → aim for Good (the first tier where results are reliable enough to act on).
    // Good → aim for Excellent (the ideal threshold). Excellent has no further target.
    private func nextTargetSentence(sampleSize: Int, predictorCount: Int) -> String? {
        guard predictorCount > 0 else { return nil }
        let targetPerPredictor: Int
        switch self {
        case .bad, .poor, .fair:
            targetPerPredictor = RegressionEngine.highSessionsPerPredictor
        case .good:
            targetPerPredictor = RegressionEngine.idealSessionsPerPredictor
        case .excellent:
            return nil
        }
        let needed = max(0, targetPerPredictor * predictorCount - sampleSize)
        guard needed > 0 else { return nil }
        let word = needed == 1 ? "session" : "sessions"
        switch self {
        case .bad, .poor, .fair:
            return "Recommend adding at least \(needed) more \(word)."
        case .good:
            return "Take accuracy to the next level by adding at least \(needed) more \(word)."
        case .excellent:
            return nil
        }
    }

    static func from(sessionsPerPredictor: Int) -> DataSufficiencyLevel {
        switch sessionsPerPredictor {
        case ..<RegressionEngine.recommendedSessionsPerPredictor: return .bad
        case ..<RegressionEngine.moderateSessionsPerPredictor: return .poor
        case ..<RegressionEngine.highSessionsPerPredictor: return .fair
        case ..<RegressionEngine.idealSessionsPerPredictor: return .good
        default: return .excellent
        }
    }

    // Correlation Analysis has no predictor dimension; callers pass the raw sample size,
    // which maps to the same threshold tiers (10/20/30/50/100).
    static func from(sampleSize: Int) -> DataSufficiencyLevel {
        from(sessionsPerPredictor: sampleSize)
    }
}

enum PredictiveAnalysisOutcome {
    case success(PredictiveAnalysisResult)
    case insufficientData(sampleSize: Int, predictorCount: Int)
    case singularMatrix(sampleSize: Int)
    case noVariance
}

enum PredictivePowerLevel {
    case weak
    case moderate
    case good
    case strong
    case veryStrong

    static func from(adjustedRSquared: Double) -> PredictivePowerLevel {
        let pct = adjustedRSquared * 100
        switch pct {
        case ..<20: return .weak
        case ..<40: return .moderate
        case ..<60: return .good
        case ..<80: return .strong
        default: return .veryStrong
        }
    }

    func headline(outcome: String) -> String {
        switch self {
        case .weak: return "Weak — these predictors have little influence on \(outcome)"
        case .moderate: return "Moderate — some relationship detected"
        case .good: return "Good — meaningful predictive relationship"
        case .strong: return "Strong — these predictors strongly influence \(outcome)"
        case .veryStrong: return "Very Strong — excellent predictive model"
        }
    }

    var shortLabel: String {
        switch self {
        case .weak: return "Weak"
        case .moderate: return "Moderate"
        case .good: return "Good"
        case .strong: return "Strong"
        case .veryStrong: return "Very Strong"
        }
    }
}

enum RegressionEngine {
    static let sessionsPerPredictor = 10             // minimum — Stevens 1992
    static let recommendedSessionsPerPredictor = 20  // Hair et al 2010 — Poor sufficiency threshold
    static let moderateSessionsPerPredictor = 30     // Fair sufficiency threshold
    static let highSessionsPerPredictor = 50         // Good sufficiency threshold
    static let idealSessionsPerPredictor = 100       // ideal — Excellent sufficiency threshold
    static let maxPredictors = 5

    static func analyze(
        sessions: [Session],
        outcome: String,
        predictors: [String]
    ) -> PredictiveAnalysisOutcome {
        guard !outcome.isEmpty, !predictors.isEmpty else {
            return .insufficientData(sampleSize: 0, predictorCount: predictors.count)
        }

        var X: [[Double]] = []
        var y: [Double] = []
        var trackSet: Set<String> = []
        var vehicleSet: Set<String> = []

        for session in sessions {
            guard let yFV = session.fieldValues.first(where: { $0.fieldName == outcome }),
                  let yVal = Double(yFV.value) else { continue }
            var row: [Double] = []
            var valid = true
            for predictor in predictors {
                guard let fv = session.fieldValues.first(where: { $0.fieldName == predictor }),
                      let val = Double(fv.value) else {
                    valid = false
                    break
                }
                row.append(val)
            }
            if valid {
                X.append(row)
                y.append(yVal)
                if !session.trackName.isEmpty { trackSet.insert(session.trackName) }
                if !session.vehicleName.isEmpty { vehicleSet.insert(session.vehicleName) }
            }
        }

        let tracks = trackSet.sorted()
        let vehicles = vehicleSet.sorted()

        let n = y.count
        let k = predictors.count
        guard n >= sessionsPerPredictor * k else {
            return .insufficientData(sampleSize: n, predictorCount: k)
        }

        let yMean = y.reduce(0, +) / Double(n)
        let yDev = y.map { $0 - yMean }
        let ySS = yDev.map { $0 * $0 }.reduce(0, +)
        guard ySS > 1e-12 else {
            return .noVariance
        }
        let ySd = sqrt(ySS / Double(n))

        var xMeans = Array(repeating: 0.0, count: k)
        var xSds = Array(repeating: 0.0, count: k)
        for j in 0..<k {
            let col = X.map { $0[j] }
            let mean = col.reduce(0, +) / Double(n)
            xMeans[j] = mean
            let ss = col.map { ($0 - mean) * ($0 - mean) }.reduce(0, +)
            if ss < 1e-12 {
                return .singularMatrix(sampleSize: n)
            }
            xSds[j] = sqrt(ss / Double(n))
        }

        let yStd = yDev.map { $0 / ySd }
        var XStd: [[Double]] = []
        for row in X {
            var stdRow: [Double] = []
            for j in 0..<k {
                stdRow.append((row[j] - xMeans[j]) / xSds[j])
            }
            XStd.append(stdRow)
        }

        var XtX = Array(repeating: Array(repeating: 0.0, count: k), count: k)
        for i in 0..<k {
            for j in 0..<k {
                var sum = 0.0
                for row in 0..<n {
                    sum += XStd[row][i] * XStd[row][j]
                }
                XtX[i][j] = sum
            }
        }
        var Xty = Array(repeating: 0.0, count: k)
        for i in 0..<k {
            var sum = 0.0
            for row in 0..<n {
                sum += XStd[row][i] * yStd[row]
            }
            Xty[i] = sum
        }

        guard let betaStar = solveLinearSystem(A: XtX, b: Xty) else {
            return .singularMatrix(sampleSize: n)
        }

        var ssRes = 0.0
        for row in 0..<n {
            var yHat = 0.0
            for j in 0..<k {
                yHat += betaStar[j] * XStd[row][j]
            }
            let r = yStd[row] - yHat
            ssRes += r * r
        }
        let ssTotStd = yStd.map { $0 * $0 }.reduce(0, +)
        let rSquared = ssTotStd > 0 ? max(0, min(1, 1 - ssRes / ssTotStd)) : 0

        let adjustedRSquared: Double = {
            let denom = n - k - 1
            guard denom > 0 else { return rSquared }
            let adj = 1 - (1 - rSquared) * Double(n - 1) / Double(denom)
            return max(0, min(1, adj))
        }()

        let dataSufficiency = DataSufficiencyLevel.from(sessionsPerPredictor: n / k)

        let totalAbs = betaStar.map { abs($0) }.reduce(0, +)
        var contributions: [PredictorContribution] = []
        for (j, name) in predictors.enumerated() {
            let share = totalAbs > 0 ? abs(betaStar[j]) / totalAbs * 100 : 0
            contributions.append(PredictorContribution(
                name: name,
                standardizedCoefficient: betaStar[j],
                sharePercent: share
            ))
        }
        contributions.sort { $0.sharePercent > $1.sharePercent }

        return .success(PredictiveAnalysisResult(
            outcome: outcome,
            predictors: predictors,
            adjustedRSquared: adjustedRSquared,
            contributions: contributions,
            sampleSize: n,
            dataSufficiency: dataSufficiency,
            tracks: tracks,
            vehicles: vehicles
        ))
    }

    // MARK: - Private helpers

    private static func solveLinearSystem(A: [[Double]], b: [Double]) -> [Double]? {
        let n = A.count
        guard n > 0, n == b.count, A[0].count == n else { return nil }

        var M = Array(repeating: Array(repeating: 0.0, count: n + 1), count: n)
        for i in 0..<n {
            for j in 0..<n {
                M[i][j] = A[i][j]
            }
            M[i][n] = b[i]
        }

        for i in 0..<n {
            var pivotRow = i
            var pivotAbs = abs(M[i][i])
            for r in (i + 1)..<n {
                if abs(M[r][i]) > pivotAbs {
                    pivotAbs = abs(M[r][i])
                    pivotRow = r
                }
            }
            if pivotAbs < 1e-10 {
                return nil
            }
            if pivotRow != i {
                M.swapAt(i, pivotRow)
            }
            for r in (i + 1)..<n {
                let factor = M[r][i] / M[i][i]
                if factor == 0 { continue }
                for c in i...n {
                    M[r][c] -= factor * M[i][c]
                }
            }
        }

        var x = Array(repeating: 0.0, count: n)
        for i in stride(from: n - 1, through: 0, by: -1) {
            var sum = M[i][n]
            for j in (i + 1)..<n {
                sum -= M[i][j] * x[j]
            }
            x[i] = sum / M[i][i]
        }
        return x
    }
}
