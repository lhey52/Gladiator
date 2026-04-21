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
    let rSquared: Double
    let contributions: [PredictorContribution]
    let sampleSize: Int
}

enum PredictiveAnalysisOutcome {
    case success(PredictiveAnalysisResult)
    case insufficientData(sampleSize: Int)
    case singularMatrix(sampleSize: Int)
    case noVariance
}

enum PredictivePowerLevel {
    case weak
    case moderate
    case good
    case strong
    case veryStrong

    static func from(rSquared: Double) -> PredictivePowerLevel {
        let pct = rSquared * 100
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
    static let minimumSessions = 5
    static let maxPredictors = 5

    static func analyze(
        sessions: [Session],
        outcome: String,
        predictors: [String]
    ) -> PredictiveAnalysisOutcome {
        guard !outcome.isEmpty, !predictors.isEmpty else {
            return .insufficientData(sampleSize: 0)
        }

        var X: [[Double]] = []
        var y: [Double] = []

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
            }
        }

        let n = y.count
        guard n >= minimumSessions else {
            return .insufficientData(sampleSize: n)
        }

        let k = predictors.count

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
            rSquared: rSquared,
            contributions: contributions,
            sampleSize: n
        ))
    }

    static func plainEnglishSummary(result: PredictiveAnalysisResult) -> String {
        guard let top = result.contributions.first else { return "" }
        var sentence = "\(top.name) is the strongest predictor of \(result.outcome), accounting for \(formatPercent(top.sharePercent)) of the model."

        let rest = Array(result.contributions.dropFirst())
        guard !rest.isEmpty else { return sentence }

        let phrases = rest.map { "\($0.name) contributes \(formatPercent($0.sharePercent))" }
        sentence += " " + joinPhrases(phrases) + "."
        return sentence
    }

    // MARK: - Private helpers

    private static func joinPhrases(_ parts: [String]) -> String {
        switch parts.count {
        case 0: return ""
        case 1: return parts[0]
        case 2: return parts.joined(separator: " and ")
        default:
            let last = parts.last ?? ""
            let allButLast = parts.dropLast().joined(separator: ", ")
            return "\(allButLast), and \(last)"
        }
    }

    private static func formatPercent(_ value: Double) -> String {
        String(format: "%.0f%%", value)
    }

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
