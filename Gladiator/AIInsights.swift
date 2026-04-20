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

    private static let priorityLowSessionTracks = 1
    private static let priorityStaleTracks = 2
    private static let priorityPersonalBestLow = 3
    private static let priorityPersonalBestHigh = 4
    private static let priorityVeryStrongCorrelation = 5
    private static let priorityStrongCorrelation = 6
    private static let priorityVeryStrongNegCorrelation = 7
    private static let priorityStrongNegCorrelation = 8
    private static let priorityTrendImproving = 9
    private static let priorityTrendDeclining = 10
    private static let priorityTrendPlateau = 11

    // MARK: - Thresholds (edit here)

    private static let minSessionsPerTrack = 5
    private static let staleDaysThreshold = 30

    // MARK: - Default message

    static let defaultMessage = "No additional insights at this time. As more sessions are added, the insights here will automatically refresh."

    // MARK: - Generate insights

    static func generate(sessions: [Session], tracks: [Track], fields: [CustomField] = []) -> [AIInsight] {
        var insights: [AIInsight] = []

        if let insight = lowSessionTrackInsight(sessions: sessions, tracks: tracks) {
            insights.append(insight)
        }
        if let insight = staleTrackInsight(sessions: sessions, tracks: tracks) {
            insights.append(insight)
        }
        insights.append(contentsOf: personalBestLowInsights(sessions: sessions, fields: fields))
        insights.append(contentsOf: personalBestHighInsights(sessions: sessions, fields: fields))
        insights.append(contentsOf: correlationInsights(sessions: sessions, fields: fields))
        insights.append(contentsOf: trendInsights(sessions: sessions, fields: fields))

        insights.sort { $0.priority < $1.priority }
        return Array(insights.prefix(5))
    }

    // MARK: - Insight: Tracks with fewer than N sessions

    private static func lowSessionTrackInsight(sessions: [Session], tracks: [Track]) -> AIInsight? {
        let sessionCountByTrack = Dictionary(grouping: sessions, by: { $0.trackName })
        let lowTracks = tracks.filter { track in
            let count = sessionCountByTrack[track.name]?.count ?? 0
            return count > 0 && count < minSessionsPerTrack
        }
        guard !lowTracks.isEmpty else { return nil }
        let names = lowTracks.map(\.name).joined(separator: ", ")
        return AIInsight(
            priority: priorityLowSessionTracks,
            message: "The following tracks have less than \(minSessionsPerTrack) sessions: \(names). Add more sessions to generate additional AI insights and unlock most analytics tools for these tracks."
        )
    }

    // MARK: - Insight: Tracks with no new session in N days

    private static func staleTrackInsight(sessions: [Session], tracks: [Track]) -> AIInsight? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -staleDaysThreshold, to: .now) ?? .now
        let latestByTrack = Dictionary(grouping: sessions, by: { $0.trackName })
            .mapValues { $0.map(\.date).max() ?? .distantPast }
        let staleTracks = tracks.filter { track in
            guard let latest = latestByTrack[track.name] else { return false }
            return latest < cutoff
        }
        guard !staleTracks.isEmpty else { return nil }
        let names = staleTracks.map(\.name).joined(separator: ", ")
        return AIInsight(
            priority: priorityStaleTracks,
            message: "You haven't added new sessions to these tracks in the last \(staleDaysThreshold) days: \(names). Consistent logging improves your analytics accuracy."
        )
    }

    // MARK: - Insight: New personal best (lowest, per-track)

    private static func personalBestLowInsights(sessions: [Session], fields: [CustomField]) -> [AIInsight] {
        let plottable = fields.filter { $0.fieldType.isPlottable }
        guard !plottable.isEmpty else { return [] }

        let byTrack = Dictionary(grouping: sessions) { $0.trackName }
        var results: [AIInsight] = []

        for (trackName, trackSessions) in byTrack {
            guard !trackName.isEmpty, trackSessions.count >= 2 else { continue }
            guard let latest = trackSessions.max(by: { $0.createdAt < $1.createdAt }) else { continue }
            let others = trackSessions.filter { $0.persistentModelID != latest.persistentModelID }
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
                    message: "Your most recent session at \(trackName) recorded your lowest ever \(field.name) at this track: \(display)."
                ))
            }
        }
        return results
    }

    // MARK: - Insight: New personal best (highest, per-track)

    private static func personalBestHighInsights(sessions: [Session], fields: [CustomField]) -> [AIInsight] {
        let plottable = fields.filter { $0.fieldType.isPlottable }
        guard !plottable.isEmpty else { return [] }

        let byTrack = Dictionary(grouping: sessions) { $0.trackName }
        var results: [AIInsight] = []

        for (trackName, trackSessions) in byTrack {
            guard !trackName.isEmpty, trackSessions.count >= 2 else { continue }
            guard let latest = trackSessions.max(by: { $0.createdAt < $1.createdAt }) else { continue }
            let others = trackSessions.filter { $0.persistentModelID != latest.persistentModelID }
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
                    message = "Your most recent session at \(trackName) recorded your highest ever \(field.name) at this track: \(display). This may be worth reviewing."
                } else {
                    message = "Your most recent session at \(trackName) recorded your highest ever \(field.name) at this track: \(display)."
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
            let t = pair.trackName

            if pair.r >= 0.7 {
                results.append(AIInsight(
                    priority: priorityVeryStrongCorrelation,
                    message: "Very strong correlation detected at \(t): higher values of \(a) are very strongly correlated with higher values of \(b) across \(n) sessions."
                ))
            } else if pair.r >= 0.5 {
                results.append(AIInsight(
                    priority: priorityStrongCorrelation,
                    message: "Strong correlation detected at \(t): higher values of \(a) are strongly correlated with higher values of \(b) across \(n) sessions."
                ))
            } else if pair.r <= -0.7 {
                results.append(AIInsight(
                    priority: priorityVeryStrongNegCorrelation,
                    message: "Very strong correlation detected at \(t): higher values of \(a) are very strongly correlated with lower values of \(b) across \(n) sessions."
                ))
            } else if pair.r <= -0.5 {
                results.append(AIInsight(
                    priority: priorityStrongNegCorrelation,
                    message: "Strong correlation detected at \(t): higher values of \(a) are strongly correlated with lower values of \(b) across \(n) sessions."
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
            results.append(AIInsight(
                priority: priorityTrendDeclining,
                message: "Declining trend detected at \(trend.trackName): your \(trend.fieldName) has been trending in a negative direction over your last \(trend.sessionCount) sessions. Consider reviewing your setup."
            ))
        }

        for trend in improving {
            results.append(AIInsight(
                priority: priorityTrendImproving,
                message: "Improving trend detected at \(trend.trackName): your \(trend.fieldName) has been trending in a positive direction over your last \(trend.sessionCount) sessions."
            ))
        }

        for trend in plateaus {
            results.append(AIInsight(
                priority: priorityTrendPlateau,
                message: "Plateau detected at \(trend.trackName): your \(trend.fieldName) has remained stable over your last \(trend.sessionCount) sessions. You may have reached your current setup ceiling."
            ))
        }

        return results
    }

    // MARK: - Helpers

    private static func formatNumber(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }
}
