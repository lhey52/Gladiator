//
//  Session.swift
//  Gladiator
//

import Foundation
import SwiftData

enum SessionType: String, CaseIterable, Codable, Identifiable {
    case practice = "Practice"
    case qualifying = "Qualifying"
    case race = "Race"

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .practice: return "PRAC"
        case .qualifying: return "QUAL"
        case .race: return "RACE"
        }
    }

    var systemImage: String {
        switch self {
        case .practice: return "stopwatch"
        case .qualifying: return "timer"
        case .race: return "flag.checkered"
        }
    }
}

@Model
final class Session {
    var date: Date
    var trackName: String
    var sessionTypeRaw: String
    var notes: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \FieldValue.session)
    var fieldValues: [FieldValue] = []

    init(
        date: Date = .now,
        trackName: String = "",
        sessionType: SessionType = .practice,
        notes: String = ""
    ) {
        self.date = date
        self.trackName = trackName
        self.sessionTypeRaw = sessionType.rawValue
        self.notes = notes
        self.createdAt = .now
    }

    var sessionType: SessionType {
        get { SessionType(rawValue: sessionTypeRaw) ?? .practice }
        set { sessionTypeRaw = newValue.rawValue }
    }
}
