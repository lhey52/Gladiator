//
//  AnalyticsSnapshot.swift
//  Gladiator
//

import Foundation
import SwiftData

// Plain value-type snapshots of the SwiftData @Model graph that powers
// analytics. The scanners (BackgroundCorrelationScanner / TrendScanner
// / ConsistencyScanner / DataQualityScanner / PredictorReadinessScanner)
// and AIInsightsEngine were previously called synchronously from view
// bodies and computed properties, with the inner loops doing repeated
// `session.fieldValues.first(where:)` / `.contains` over a SwiftData
// @Relationship. With ~40 sessions × ~40 metrics every body
// re-evaluation became a multi-second main-thread stall.
//
// Snapshots fix this by giving every scanner a Sendable, value-type
// view of the data:
// - SessionSnapshot.fieldValues is a `[String: FieldValueSnapshot]`,
//   so the inner-loop lookup is O(1) instead of O(n) and never touches
//   SwiftData faults.
// - The whole AnalyticsSnapshot is Sendable, so the calc can move to
//   `Task.detached`. ModelContext stays on the main actor.
// All snapshot inits read SwiftData and are therefore @MainActor.

struct FieldValueSnapshot: Sendable, Hashable {
    let fieldName: String
    let fieldType: FieldType
    let value: String

    var doubleValue: Double? { Double(value) }

    var hasNonEmptyValue: Bool {
        !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct SessionSnapshot: Sendable, Hashable, Identifiable {
    let id: PersistentIdentifier
    let date: Date
    let createdAt: Date
    let trackName: String
    let vehicleName: String
    let sessionType: SessionType
    /// Field values keyed by `fieldName` for O(1) lookup. Replaces the
    /// previous `session.fieldValues.first(where:)` hot path that
    /// re-scanned a SwiftData relationship per inner-loop call.
    let fieldValues: [String: FieldValueSnapshot]

    @MainActor
    init(_ session: Session) {
        self.id = session.persistentModelID
        self.date = session.date
        self.createdAt = session.createdAt
        self.trackName = session.trackName
        self.vehicleName = session.vehicleName
        self.sessionType = session.sessionType
        var dict: [String: FieldValueSnapshot] = [:]
        dict.reserveCapacity(session.fieldValues.count)
        for fv in session.fieldValues {
            dict[fv.fieldName] = FieldValueSnapshot(
                fieldName: fv.fieldName,
                fieldType: fv.fieldType,
                value: fv.value
            )
        }
        self.fieldValues = dict
    }
}

struct CustomFieldSnapshot: Sendable, Hashable, Identifiable {
    let id: PersistentIdentifier
    let name: String
    let fieldType: FieldType
    let sortOrder: Int
    let zone: CarZone

    var isPlottable: Bool { fieldType.isPlottable }

    @MainActor
    init(_ field: CustomField) {
        self.id = field.persistentModelID
        self.name = field.name
        self.fieldType = field.fieldType
        self.sortOrder = field.sortOrder
        self.zone = field.zone
    }
}

struct AnalyticsSnapshot: Sendable {
    let sessions: [SessionSnapshot]
    let fields: [CustomFieldSnapshot]

    @MainActor
    init(sessions: [Session], fields: [CustomField]) {
        self.sessions = sessions.map(SessionSnapshot.init)
        self.fields = fields.map(CustomFieldSnapshot.init)
    }

    init(sessions: [SessionSnapshot], fields: [CustomFieldSnapshot]) {
        self.sessions = sessions
        self.fields = fields
    }
}
