//
//  Vehicle.swift
//  Gladiator
//

import Foundation
import SwiftData

@Model
final class Vehicle {
    var name: String
    var isDefault: Bool
    var createdAt: Date

    init(name: String = "", isDefault: Bool = false) {
        self.name = name
        self.isDefault = isDefault
        self.createdAt = .now
    }

    static func combine(name: String, driver: String) -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedDriver = driver.trimmingCharacters(in: .whitespaces)
        if trimmedDriver.isEmpty { return trimmedName }
        return "\(trimmedName) (\(trimmedDriver))"
    }

    static func split(name combined: String) -> (name: String, driver: String) {
        guard combined.hasSuffix(")"),
              let openParenIndex = combined.lastIndex(of: "(") else {
            return (combined, "")
        }
        let indexBeforeParen = combined.index(before: openParenIndex)
        guard indexBeforeParen >= combined.startIndex,
              combined[indexBeforeParen] == " " else {
            return (combined, "")
        }
        let name = String(combined[..<indexBeforeParen])
        let driverStart = combined.index(after: openParenIndex)
        let driverEnd = combined.index(before: combined.endIndex)
        let driver = String(combined[driverStart..<driverEnd])
        return (
            name.trimmingCharacters(in: .whitespaces),
            driver.trimmingCharacters(in: .whitespaces)
        )
    }
}
