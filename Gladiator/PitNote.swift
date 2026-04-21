//
//  PitNote.swift
//  Gladiator
//

import Foundation
import SwiftData

@Model
final class PitNote {
    var title: String
    var bodyText: String
    var createdAt: Date
    var updatedAt: Date

    init(title: String = "", bodyText: String = "") {
        self.title = title
        self.bodyText = bodyText
        self.createdAt = .now
        self.updatedAt = .now
    }
}
