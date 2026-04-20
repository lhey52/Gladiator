//
//  Track.swift
//  Gladiator
//

import Foundation
import SwiftData

@Model
final class Track {
    var name: String
    var isDefault: Bool
    var createdAt: Date

    init(name: String = "", isDefault: Bool = false) {
        self.name = name
        self.isDefault = isDefault
        self.createdAt = .now
    }
}
