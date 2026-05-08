//
//  DashboardMessages.swift
//  Gladiator
//

import Foundation

enum DashboardMessages {

    // MARK: - Context message definitions (evaluated in priority order)

    private struct ContextMessage {
        let condition: ([Date], DriverProfile) -> Bool
        let probability: Double
        let message: (DriverProfile) -> String
    }

    struct DriverProfile: Sendable {
        let firstName: String
        let teamName: String
        let racingNumber: String

        var displayName: String {
            firstName.isEmpty ? "Driver" : firstName
        }
    }

    private static let contextMessages: [ContextMessage] = [
        ContextMessage(
            condition: { dates, _ in
                guard let latest = dates.max() else { return false }
                return Calendar.current.isDateInToday(latest)
            },
            probability: 1.0,
            message: { profile in "Strong work today, \(profile.displayName)" }
        ),
        ContextMessage(
            condition: { dates, _ in
                guard let latest = dates.max() else { return true }
                let days = Calendar.current.dateComponents([.day], from: latest, to: .now).day ?? 0
                return days >= 30
            },
            probability: 1.0,
            message: { profile in "The track is waiting, \(profile.displayName)" }
        ),
        ContextMessage(
            condition: { dates, _ in
                guard let latest = dates.max() else { return false }
                let days = Calendar.current.dateComponents([.day], from: latest, to: .now).day ?? 0
                return days >= 7
            },
            probability: 1.0,
            message: { profile in "Time to get back on track, \(profile.displayName)" }
        ),
        ContextMessage(
            condition: { _, profile in !profile.racingNumber.isEmpty },
            probability: 0.2,
            message: { profile in "Driver #\(profile.racingNumber), ready to analyze?" }
        ),
        ContextMessage(
            condition: { _, profile in !profile.teamName.isEmpty },
            probability: 0.2,
            message: { profile in "\(profile.teamName) — let's review the data." }
        )
    ]

    // MARK: - Time of day messages (100% fallback)

    private static func timeOfDayMessage(profile: DriverProfile) -> String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:
            return "Good morning, \(profile.displayName)"
        case 12..<17:
            return "Good afternoon, \(profile.displayName)"
        case 17..<21:
            return "Good evening, \(profile.displayName)"
        default:
            return "Late night session, \(profile.displayName)?"
        }
    }

    // MARK: - Generate greeting

    // Takes Sendable inputs ([Date] + DriverProfile) so the caller can
    // hand them to a detached task. Previously took [Session] (a
    // SwiftData @Model class, not Sendable) — but only `session.date`
    // was ever read, so the snapshot is just the dates.
    static func generate(sessionDates: [Date], profile: DriverProfile) -> String {
        for ctx in contextMessages {
            guard ctx.condition(sessionDates, profile) else { continue }
            if ctx.probability >= 1.0 || Double.random(in: 0..<1) < ctx.probability {
                return ctx.message(profile)
            }
        }
        return timeOfDayMessage(profile: profile)
    }
}
