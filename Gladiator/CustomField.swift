//
//  CustomField.swift
//  Gladiator
//

import Foundation
import SwiftData

enum FieldType: String, CaseIterable, Codable, Identifiable {
    case number = "Number"
    case text = "Text"
    case time = "Time"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .number: return "number"
        case .text: return "textformat"
        case .time: return "stopwatch"
        }
    }

    var isPlottable: Bool {
        self == .number || self == .time
    }
}

enum TimeFormatting {
    static func secondsToDisplay(_ totalSeconds: Double) -> String {
        let isNegative = totalSeconds < 0
        let abs = Swift.abs(totalSeconds)
        let hours = Int(abs) / 3600
        let minutes = (Int(abs) % 3600) / 60
        let seconds = Int(abs) % 60
        let millis = Int((abs.truncatingRemainder(dividingBy: 1)) * 1000)
        let prefix = isNegative ? "-" : ""
        if hours > 0 {
            return String(format: "%@%d:%02d:%02d.%03d", prefix, hours, minutes, seconds, millis)
        }
        return String(format: "%@%d:%02d.%03d", prefix, minutes, seconds, millis)
    }

    static func displayToSeconds(_ display: String) -> Double? {
        let parts = display.split(separator: ":")
        switch parts.count {
        case 2:
            guard let min = Double(parts[0]),
                  let sec = Double(parts[1]) else { return nil }
            return min * 60 + sec
        case 3:
            guard let hr = Double(parts[0]),
                  let min = Double(parts[1]),
                  let sec = Double(parts[2]) else { return nil }
            return hr * 3600 + min * 60 + sec
        default:
            return Double(display)
        }
    }

    static func secondsToAxisLabel(_ totalSeconds: Double) -> String {
        let abs = Swift.abs(totalSeconds)
        let minutes = Int(abs) / 60
        let seconds = Int(abs) % 60
        let prefix = totalSeconds < 0 ? "-" : ""
        return String(format: "%@%d:%02d", prefix, minutes, seconds)
    }
}

@Model
final class CustomField {
    var name: String
    var fieldTypeRaw: String
    var sortOrder: Int
    var createdAt: Date
    // Step size is only meaningful for Number metrics — it captures the
    // smallest increment the driver can realistically dial in. Stored as
    // optional so existing rows lightweight-migrate to nil and so Text/Time
    // metrics can omit it entirely. A value of 0 marks the metric as outside
    // the driver's control (e.g. ambient temperature).
    var stepSize: Double?
    // Race car zone assignment used by the visual zone interface in the
    // Add/Edit Session forms. Stored as a raw String with a default of
    // "General" so existing rows lightweight-migrate without manual fixup.
    var zoneRaw: String = CarZone.general.rawValue

    init(
        name: String = "",
        fieldType: FieldType = .text,
        sortOrder: Int = 0,
        stepSize: Double? = nil,
        zone: CarZone = .general
    ) {
        self.name = name
        self.fieldTypeRaw = fieldType.rawValue
        self.sortOrder = sortOrder
        self.createdAt = .now
        self.stepSize = stepSize
        self.zoneRaw = zone.rawValue
    }

    var fieldType: FieldType {
        get { FieldType(rawValue: fieldTypeRaw) ?? .text }
        set { fieldTypeRaw = newValue.rawValue }
    }

    var zone: CarZone {
        get {
            // Legacy "Cockpit" rawValues map to .chassis after the
            // 1.x rename so prior field assignments still resolve to
            // a valid zone. New writes persist as "Chassis".
            if zoneRaw == "Cockpit" { return .chassis }
            return CarZone(rawValue: zoneRaw) ?? .general
        }
        set { zoneRaw = newValue.rawValue }
    }

    // Prepend the zone's prefix to a name. Idempotent: skips if the name
    // is already prefixed (so users who manually type "FL …" in the
    // metric form don't end up with "FL FL …" on save). General returns
    // the input unchanged because its prefix is empty.
    static func applyPrefix(to name: String, zone: CarZone) -> String {
        let prefix = zone.metricNamePrefix
        guard !prefix.isEmpty else { return name }
        if name.hasPrefix(prefix) { return name }
        return prefix + name
    }

    // Inverse of applyPrefix — used when rendering a metric inside its
    // own zone interface (the prefix is redundant there) and when
    // pre-filling the Edit Metric form.
    static func stripPrefix(from name: String, zone: CarZone) -> String {
        let prefix = zone.metricNamePrefix
        guard !prefix.isEmpty, name.hasPrefix(prefix) else { return name }
        return String(name.dropFirst(prefix.count))
    }

    static func combine(name: String, unit: String) -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedUnit = unit.trimmingCharacters(in: .whitespaces)
        if trimmedUnit.isEmpty { return trimmedName }
        return "\(trimmedName) (\(trimmedUnit))"
    }

    static func split(name combined: String) -> (name: String, unit: String) {
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
        let unitStart = combined.index(after: openParenIndex)
        let unitEnd = combined.index(before: combined.endIndex)
        let unit = String(combined[unitStart..<unitEnd])
        return (
            name.trimmingCharacters(in: .whitespaces),
            unit.trimmingCharacters(in: .whitespaces)
        )
    }
}

@Model
final class FieldValue {
    var value: String
    var fieldName: String
    var fieldTypeRaw: String
    var session: Session?

    init(fieldName: String, fieldType: FieldType, value: String = "", session: Session? = nil) {
        self.fieldName = fieldName
        self.fieldTypeRaw = fieldType.rawValue
        self.value = value
        self.session = session
    }

    var fieldType: FieldType {
        get { FieldType(rawValue: fieldTypeRaw) ?? .text }
        set { fieldTypeRaw = newValue.rawValue }
    }
}
