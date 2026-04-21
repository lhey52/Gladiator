//
//  PitReminder.swift
//  Gladiator
//

import Foundation
import SwiftData

@Model
final class PitReminder {
    var title: String
    var note: String
    var dueDate: Date
    var isCompleted: Bool
    var notificationID: String
    var createdAt: Date

    init(
        title: String = "",
        note: String = "",
        dueDate: Date = .now.addingTimeInterval(3600)
    ) {
        self.title = title
        self.note = note
        self.dueDate = dueDate
        self.isCompleted = false
        self.notificationID = UUID().uuidString
        self.createdAt = .now
    }

    var isOverdue: Bool {
        !isCompleted && dueDate < .now
    }
}
