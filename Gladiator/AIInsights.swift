//
//  AIInsights.swift
//  Gladiator
//

import Foundation

struct AIInsight: Identifiable {
    let id = UUID()
    let priority: Int
    let message: String
}

enum AIInsightsEngine {

    // MARK: - Priority rankings (lower = higher priority, edit here)

    private static let priorityLowSessionCombos = 1
    private static let priorityStaleCombos = 2
    private static let priorityPersonalBestLow = 3
    private static let priorityPersonalBestHigh = 4
    private static let priorityVeryStrongCorrelation = 5
    private static let priorityStrongCorrelation = 6
    private static let priorityVeryStrongNegCorrelation = 7
    private static let priorityStrongNegCorrelation = 8
    private static let priorityTrendImproving = 9
    private static let priorityTrendDeclining = 10
    private static let priorityTrendPlateau = 11
    private static let priorityMostConsistent = 12
    private static let priorityHighVariance = 13

    // MARK: - Thresholds (edit here)

    private static let minSessionsPerCombo = 5
    private static let staleDaysThreshold = 30
    private static let highVarianceThreshold = 0.3

    // MARK: - Default message

    static let defaultMessage = "No additional insights at this time. As more sessions are added, the insights here will automatically refresh."

    // MARK: - Group key

    private struct ComboKey: Hashable {
        let track: String
        let vehicle: String

        var label: String {
            if vehicle.isEmpty { return track }
            return "\(track) in \(vehicle)"
        }
    }

    // MARK: - Generate insights

    static func generate(
        sessions: [Session],
        tracks: [Track],
        fields: [CustomField] = [],
        maxInsights: Int = 5
    ) -> [AIInsight] {
        var insights: [AIInsight] = []

        if let insight = lowSessionComboInsight(sessions: sessions) {
            insights.append(insight)
        }
        if let insight = staleComboInsight(sessions: sessions) {
            insights.append(insight)
        }
        insights.append(contentsOf: personalBestLowInsights(sessions: sessions, fields: fields))
        insights.append(contentsOf: personalBestHighInsights(sessions: sessions, fields: fields))
        insights.append(contentsOf: correlationInsights(sessions: sessions, fields: fields))
        insights.append(contentsOf: trendInsights(sessions: sessions, fields: fields))
        insights.append(contentsOf: consistencyInsights(sessions: sessions, fields: fields))

        insights.sort { $0.priority < $1.priority }
        return Array(insights.prefix(max(1, maxInsights)))
    }

    // MARK: - Insight: Combos with fewer than N sessions

    private static func lowSessionComboInsight(sessions: [Session]) -> AIInsight? {
        let grouped = Dictionary(grouping: sessions) { ComboKey(track: $0.trackName, vehicle: $0.vehicleName) }
        let lowCombos = grouped.filter { key, group in
            !key.track.isEmpty && group.count > 0 && group.count < minSessionsPerCombo
        }
        guard !lowCombos.isEmpty else { return nil }
        let names = lowCombos.keys.map(\.label).sorted().joined(separator: ", ")
        return AIInsight(
            priority: priorityLowSessionCombos,
            message: "The following track and vehicle combinations have less than \(minSessionsPerCombo) sessions: \(names). Add more sessions to generate additional AI insights and unlock most analytics tools for these combinations."
        )
    }

    // MARK: - Insight: Combos with no new session in N days

    private static func staleComboInsight(sessions: [Session]) -> AIInsight? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -staleDaysThreshold, to: .now) ?? .now
        let grouped = Dictionary(grouping: sessions) { ComboKey(track: $0.trackName, vehicle: $0.vehicleName) }
        let staleCombos = grouped.filter { key, group in
            guard !key.track.isEmpty else { return false }
            let latest = group.map(\.date).max() ?? .distantPast
            return latest < cutoff
        }
        guard !staleCombos.isEmpty else { return nil }
        let names = staleCombos.keys.map(\.label).sorted().joined(separator: ", ")
        return AIInsight(
            priority: priorityStaleCombos,
            message: "You haven't added new sessions for these track and vehicle combinations in the last \(staleDaysThreshold) days: \(names). Consistent logging improves your analytics accuracy."
        )
    }

    // MARK: - Insight: New personal best (lowest, per combo)

    private static func personalBestLowInsights(sessions: [Session], fields: [CustomField]) -> [AIInsight] {
        let plottable = fields.filter { $0.fieldType.isPlottable }
        guard !plottable.isEmpty else { return [] }

        let grouped = Dictionary(grouping: sessions) { ComboKey(track: $0.trackName, vehicle: $0.vehicleName) }
        var results: [AIInsight] = []

        for (key, comboSessions) in grouped {
            guard !key.track.isEmpty, comboSessions.count >= 2 else { continue }
            guard let latest = comboSessions.max(by: { $0.createdAt < $1.createdAt }) else { continue }
            let others = comboSessions.filter { $0.persistentModelID != latest.persistentModelID }
            guard !others.isEmpty else { continue }

            for field in plottable {
                guard let latestFV = latest.fieldValues.first(where: { $0.fieldName == field.name }),
                      let latestVal = Double(latestFV.value) else { continue }

                let previousValues = others.compactMap { session -> Double? in
                    guard let fv = session.fieldValues.first(where: { $0.fieldName == field.name }) else { return nil }
                    return Double(fv.value)
                }
                guard !previousValues.isEmpty else { continue }
                guard let previousMin = previousValues.min(), latestVal < previousMin else { continue }

                let display = field.fieldType == .time
                    ? TimeFormatting.secondsToDisplay(latestVal)
                    : formatNumber(latestVal)

                results.append(AIInsight(
                    priority: priorityPersonalBestLow,
                    message: "Your most recent session at \(key.label) recorded your lowest ever \(field.name) at this track and vehicle combination: \(display)."
                ))
            }
        }
        return results
    }

    // MARK: - Insight: New personal best (highest, per combo)

    private static func personalBestHighInsights(sessions: [Session], fields: [CustomField]) -> [AIInsight] {
        let plottable = fields.filter { $0.fieldType.isPlottable }
        guard !plottable.isEmpty else { return [] }

        let grouped = Dictionary(grouping: sessions) { ComboKey(track: $0.trackName, vehicle: $0.vehicleName) }
        var results: [AIInsight] = []

        for (key, comboSessions) in grouped {
            guard !key.track.isEmpty, comboSessions.count >= 2 else { continue }
            guard let latest = comboSessions.max(by: { $0.createdAt < $1.createdAt }) else { continue }
            let others = comboSessions.filter { $0.persistentModelID != latest.persistentModelID }
            guard !others.isEmpty else { continue }

            for field in plottable {
                guard let latestFV = latest.fieldValues.first(where: { $0.fieldName == field.name }),
                      let latestVal = Double(latestFV.value) else { continue }

                let previousValues = others.compactMap { session -> Double? in
                    guard let fv = session.fieldValues.first(where: { $0.fieldName == field.name }) else { return nil }
                    return Double(fv.value)
                }
                guard !previousValues.isEmpty else { continue }
                guard let previousMax = previousValues.max(), latestVal > previousMax else { continue }

                let display = field.fieldType == .time
                    ? TimeFormatting.secondsToDisplay(latestVal)
                    : formatNumber(latestVal)

                let message: String
                if field.fieldType == .time {
                    message = "Your most recent session at \(key.label) recorded your highest ever \(field.name) at this track and vehicle combination: \(display). This may be worth reviewing."
                } else {
                    message = "Your most recent session at \(key.label) recorded your highest ever \(field.name) at this track and vehicle combination: \(display)."
                }

                results.append(AIInsight(
                    priority: priorityPersonalBestHigh,
                    message: message
                ))
            }
        }
        return results
    }

    // MARK: - Insight: Background correlation scan

    private static func correlationInsights(sessions: [Session], fields: [CustomField]) -> [AIInsight] {
        let pairs = BackgroundCorrelationScanner.scanAll(sessions: sessions, fields: fields)
        let sorted = pairs.sorted { abs($0.r) > abs($1.r) }

        var results: [AIInsight] = []
        for pair in sorted {
            let n = pair.sampleSize
            let a = pair.fieldA
            let b = pair.fieldB
            let loc = pair.vehicleName.isEmpty ? pair.trackName : "\(pair.trackName) in \(pair.vehicleName)"

            if pair.r >= 0.7 {
                results.append(AIInsight(
                    priority: priorityVeryStrongCorrelation,
                    message: "Very strong correlation detected at \(loc): higher values of \(a) are very strongly correlated with higher values of \(b) across \(n) sessions."
                ))
            } else if pair.r >= 0.5 {
                results.append(AIInsight(
                    priority: priorityStrongCorrelation,
                    message: "Strong correlation detected at \(loc): higher values of \(a) are strongly correlated with higher values of \(b) across \(n) sessions."
                ))
            } else if pair.r <= -0.7 {
                results.append(AIInsight(
                    priority: priorityVeryStrongNegCorrelation,
                    message: "Very strong correlation detected at \(loc): higher values of \(a) are very strongly correlated with lower values of \(b) across \(n) sessions."
                ))
            } else if pair.r <= -0.5 {
                results.append(AIInsight(
                    priority: priorityStrongNegCorrelation,
                    message: "Strong correlation detected at \(loc): higher values of \(a) are strongly correlated with lower values of \(b) across \(n) sessions."
                ))
            }
        }
        return results
    }

    // MARK: - Insight: Background trend scan

    private static func trendInsights(sessions: [Session], fields: [CustomField]) -> [AIInsight] {
        let trends = BackgroundTrendScanner.scanAll(sessions: sessions, fields: fields)

        let declining = trends.filter { $0.classification == .declining }
        let improving = trends.filter { $0.classification == .improving }
        let plateaus = trends.filter { $0.classification == .plateau }

        var results: [AIInsight] = []

        for trend in declining {
            let loc = trend.vehicleName.isEmpty ? trend.trackName : "\(trend.trackName) in \(trend.vehicleName)"
            results.append(AIInsight(
                priority: priorityTrendDeclining,
                message: "Declining trend detected at \(loc): your \(trend.fieldName) has been trending in a negative direction over your last \(trend.sessionCount) sessions. Consider reviewing your setup."
            ))
        }

        for trend in improving {
            let loc = trend.vehicleName.isEmpty ? trend.trackName : "\(trend.trackName) in \(trend.vehicleName)"
            results.append(AIInsight(
                priority: priorityTrendImproving,
                message: "Improving trend detected at \(loc): your \(trend.fieldName) has been trending in a positive direction over your last \(trend.sessionCount) sessions."
            ))
        }

        for trend in plateaus {
            let loc = trend.vehicleName.isEmpty ? trend.trackName : "\(trend.trackName) in \(trend.vehicleName)"
            results.append(AIInsight(
                priority: priorityTrendPlateau,
                message: "Plateau detected at \(loc): your \(trend.fieldName) has remained stable over your last \(trend.sessionCount) sessions. You may have reached your current setup ceiling."
            ))
        }

        return results
    }

    // MARK: - Insight: Background consistency scan

    private static func consistencyInsights(sessions: [Session], fields: [CustomField]) -> [AIInsight] {
        let results = BackgroundConsistencyScanner.scanAll(sessions: sessions, fields: fields)
        guard !results.isEmpty else { return [] }

        var insights: [AIInsight] = []

        // Most consistent metric per track+vehicle combination
        let grouped = Dictionary(grouping: results) { ComboKey(track: $0.trackName, vehicle: $0.vehicleName) }
        for (_, metrics) in grouped {
            guard let best = metrics.min(by: { $0.coefficientOfVariation < $1.coefficientOfVariation }) else { continue }
            let loc = best.vehicleName.isEmpty ? "at \(best.trackName)" : "at \(best.trackName) in \(best.vehicleName)"
            insights.append(AIInsight(
                priority: priorityMostConsistent,
                message: "Your most consistently recorded metric \(loc) is \(best.fieldName). Strong consistency here gives you reliable data to work with."
            ))
        }

        // High variance warnings for any metric+combo above the threshold
        for result in results where result.coefficientOfVariation > highVarianceThreshold {
            let loc = result.vehicleName.isEmpty ? "at \(result.trackName)" : "at \(result.trackName) in \(result.vehicleName)"
            insights.append(AIInsight(
                priority: priorityHighVariance,
                message: "Your \(result.fieldName) \(loc) shows high variability across sessions. Improving consistency here could improve your setup reliability."
            ))
        }

        return insights
    }

    // MARK: - Helpers

    private static func formatNumber(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }
}
