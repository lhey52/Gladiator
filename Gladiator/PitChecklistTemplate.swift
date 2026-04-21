//
//  PitChecklistTemplate.swift
//  Gladiator
//

import Foundation
import SwiftData

@Model
final class PitChecklistTemplate {
    var name: String
    var sortOrder: Int
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \PitChecklistItem.template)
    var items: [PitChecklistItem] = []

    init(name: String = "", sortOrder: Int = 0) {
        self.name = name
        self.sortOrder = sortOrder
        self.createdAt = .now
    }

    var sortedItems: [PitChecklistItem] {
        items.sorted { $0.sortOrder < $1.sortOrder }
    }

    var checkedCount: Int {
        items.filter { $0.isChecked }.count
    }
}

@Model
final class PitChecklistItem {
    var text: String
    var isChecked: Bool
    var sortOrder: Int
    var template: PitChecklistTemplate?

    init(text: String = "", sortOrder: Int = 0) {
        self.text = text
        self.isChecked = false
        self.sortOrder = sortOrder
    }
}
