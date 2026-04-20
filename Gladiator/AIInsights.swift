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
            message: "The following tracks have less than \(minSessionsPerTrack) sessions: \(names). Add more sessions to unlock most analytics tools for these tracks."
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

    // MARK: - Insight: New personal best (lowest, track-specific)

    private static func personalBestLowInsights(sessions: [Session], fields: [CustomField]) -> [AIInsight] {
        guard let latest = sessions.max(by: { $0.createdAt < $1.createdAt }),
              !latest.trackName.isEmpty else { return [] }
        let trackName = latest.trackName
        let others = sessions.filter { $0.persistentModelID != latest.persistentModelID && $0.trackName == trackName }
        guard !others.isEmpty else { return [] }

        let plottable = fields.filter { $0.fieldType.isPlottable }
        var results: [AIInsight] = []

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
        return results
    }

    // MARK: - Insight: New personal best (highest, track-specific)

    private static func personalBestHighInsights(sessions: [Session], fields: [CustomField]) -> [AIInsight] {
        guard let latest = sessions.max(by: { $0.createdAt < $1.createdAt }),
              !latest.trackName.isEmpty else { return [] }
        let trackName = latest.trackName
        let others = sessions.filter { $0.persistentModelID != latest.persistentModelID && $0.trackName == trackName }
        guard !others.isEmpty else { return [] }

        let plottable = fields.filter { $0.fieldType.isPlottable }
        var results: [AIInsight] = []

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
