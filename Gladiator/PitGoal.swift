//
//  PitGoal.swift
//  Gladiator
//

import Foundation
import SwiftData
import SwiftUI

enum GoalStatus: String, CaseIterable, Codable, Identifiable {
    case inProgress = "In Progress"
    case notStarted = "Not Started"
    case achieved = "Achieved"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .notStarted: return "circle"
        case .inProgress: return "bolt.fill"
        case .achieved: return "checkmark.seal.fill"
        }
    }

    var color: Color {
        switch self {
        case .notStarted: return Theme.textTertiary
        case .inProgress: return Theme.accent
        case .achieved: return Theme.accent
        }
    }

    var sortIndex: Int {
        switch self {
        case .inProgress: return 0
        case .notStarted: return 1
        case .achieved: return 2
        }
    }
}

@Model
final class PitGoal {
    var title: String
    var details: String
    var targetValue: String
    var targetDate: Date?
    var statusRaw: String
    var createdAt: Date

    init(
        title: String = "",
        details: String = "",
        targetValue: String = "",
        targetDate: Date? = nil,
        status: GoalStatus = .notStarted
    ) {
        self.title = title
        self.details = details
        self.targetValue = targetValue
        self.targetDate = targetDate
        self.statusRaw = status.rawValue
        self.createdAt = .now
    }

    var status: GoalStatus {
        get { GoalStatus(rawValue: statusRaw) ?? .notStarted }
        set { statusRaw = newValue.rawValue }
    }
}
