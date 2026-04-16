//
//  CustomField.swift
//  Gladiator
//

import Foundation
import SwiftData

enum FieldType: String, CaseIterable, Codable, Identifiable {
    case number = "Number"
    case text = "Text"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .number: return "number"
        case .text: return "textformat"
        }
    }
}

@Model
final class CustomField {
    var name: String
    var fieldTypeRaw: String
    var sortOrder: Int
    var createdAt: Date

    init(name: String = "", fieldType: FieldType = .text, sortOrder: Int = 0) {
        self.name = name
        self.fieldTypeRaw = fieldType.rawValue
        self.sortOrder = sortOrder
        self.createdAt = .now
    }

    var fieldType: FieldType {
        get { FieldType(rawValue: fieldTypeRaw) ?? .text }
        set { fieldTypeRaw = newValue.rawValue }
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
