//
//  DashboardMessages.swift
//  Gladiator
//

import Foundation

enum DashboardMessages {

    // MARK: - Context message definitions (evaluated in priority order)

    private struct ContextMessage {
        let condition: ([Session], DriverProfile) -> Bool
        let probability: Double
        let message: (DriverProfile) -> String
    }

    struct DriverProfile {
        let firstName: String
        let teamName: String
        let racingNumber: String

        var displayName: String {
            firstName.isEmpty ? "Driver" : firstName
        }
    }

    private static let contextMessages: [ContextMessage] = [
        ContextMessage(
            condition: { sessions, _ in
                guard let latest = sessions.max(by: { $0.date < $1.date }) else { return false }
                return Calendar.current.isDateInToday(latest.date)
            },
            probability: 1.0,
            message: { profile in "Strong work today, \(profile.displayName)" }
        ),
        ContextMessage(
            condition: { sessions, _ in
                guard let latest = sessions.max(by: { $0.date < $1.date }) else { return true }
                let days = Calendar.current.dateComponents([.day], from: latest.date, to: .now).day ?? 0
                return days >= 30
            },
            probability: 1.0,
            message: { profile in "The track is waiting, \(profile.displayName)" }
        ),
        ContextMessage(
            condition: { sessions, _ in
                guard let latest = sessions.max(by: { $0.date < $1.date }) else { return false }
                let days = Calendar.current.dateComponents([.day], from: latest.date, to: .now).day ?? 0
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

    static func generate(sessions: [Session], profile: DriverProfile) -> String {
        for ctx in contextMessages {
            guard ctx.condition(sessions, profile) else { continue }
            if ctx.probability >= 1.0 || Double.random(in: 0..<1) < ctx.probability {
                return ctx.message(profile)
            }
        }
        return timeOfDayMessage(profile: profile)
    }
}
