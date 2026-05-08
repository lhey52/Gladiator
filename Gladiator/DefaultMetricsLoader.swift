//
//  DefaultMetricsLoader.swift
//  Gladiator
//

import Foundation
import SwiftData

// One-shot seeder for the standard set of preloaded metrics covering the
// four tire zones, the chassis, and a couple of weather fields in
// General. `loadIfNeeded(into:)` runs once on fresh install (gated by a
// UserDefaults flag) and is wired up on app launch from ContentView.
// `load(into:)` is idempotent — every CustomField is checked against the
// store by combined-name + zone (case-insensitive) before insert, so it
// can also be triggered manually from the Demo Seeder admin without
// duplicating anything the user has already added.
enum DefaultMetricsLoader {
    private static let firstRunKey = "defaultMetricsLoadedV1"

    static func loadIfNeeded(into context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: firstRunKey) else { return }
        load(into: context)
        UserDefaults.standard.set(true, forKey: firstRunKey)
    }

    @discardableResult
    static func load(into context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<CustomField>()
        let existing = (try? context.fetch(descriptor)) ?? []
        let existingKeys = Set(existing.map { dedupKey(name: $0.name, zone: $0.zone) })
        var nextOrder = (existing.map(\.sortOrder).max() ?? -1) + 1
        var inserted = 0

        for spec in specs {
            let combinedName = CustomField.combine(name: spec.name, unit: spec.unit)
            let prefixedName = CustomField.applyPrefix(to: combinedName, zone: spec.zone)
            let key = dedupKey(name: prefixedName, zone: spec.zone)
            guard !existingKeys.contains(key) else { continue }

            context.insert(CustomField(
                name: prefixedName,
                fieldType: spec.fieldType,
                sortOrder: nextOrder,
                stepSize: spec.stepSize,
                zone: spec.zone
            ))
            nextOrder += 1
            inserted += 1
        }

        if inserted > 0 {
            try? context.save()
        }
        return inserted
    }

    private static func dedupKey(name: String, zone: CarZone) -> String {
        // Compare against the bare (un-prefixed) name so a previously
        // unprefixed seed and a freshly prefixed seed of the same
        // logical metric collapse onto the same key.
        let stripped = CustomField.stripPrefix(from: name, zone: zone)
        return "\(stripped.lowercased())|\(zone.rawValue.lowercased())"
    }

    private struct Spec {
        let name: String
        let unit: String
        let fieldType: FieldType
        // Optional so .time and .text metrics can persist without a
        // step size — the rest of the app already treats stepSize as
        // meaningless for non-Number metrics and nils it out on type
        // change in EditMetricView.performSave.
        let stepSize: Double?
        let zone: CarZone
    }

    // The four tire zones share the same metric set, so the list is
    // generated programmatically rather than hand-pasting four
    // duplicates.
    private static let specs: [Spec] = {
        let tireMetrics: [(name: String, unit: String, step: Double)] = [
            ("Cold Tire Pressure", "PSI", 0.5),
            ("Hot Tire Pressure", "PSI", 0.5),
            ("Shock Travel", "inches", 0.1),
            ("Inside Tire Temp", "degrees F", 1),
            ("Middle Tire Temp", "degrees F", 1),
            ("Outside Tire Temp", "degrees F", 1)
        ]
        let tireZones: [CarZone] = [.flTire, .frTire, .blTire, .brTire]

        var all: [Spec] = []
        for zone in tireZones {
            for metric in tireMetrics {
                all.append(Spec(
                    name: metric.name,
                    unit: metric.unit,
                    fieldType: .number,
                    stepSize: metric.step,
                    zone: zone
                ))
            }
        }

        let chassisMetrics: [(name: String, unit: String, step: Double)] = [
            ("X-Member Tabs", "inches", 0.1),
            ("Swaybar Rds", "inches", 0.1),
            ("Rear Stagger", "inches", 0.1),
            ("Front Stagger", "inches", 0.1),
            ("Trailing Arm Adj", "inches", 0.1),
            ("Camber Shim Adj", "inches", 0.1),
            ("Spring Rubber Adj", "inches", 0.1),
            ("Top Link", "degrees", 0.5)
        ]
        for metric in chassisMetrics {
            all.append(Spec(
                name: metric.name,
                unit: metric.unit,
                fieldType: .number,
                stepSize: metric.step,
                zone: .chassis
            ))
        }

        let generalMetrics: [(name: String, unit: String, step: Double)] = [
            ("Outside Temp", "degrees F", 1),
            ("Humidity", "%", 1)
        ]
        for metric in generalMetrics {
            all.append(Spec(
                name: metric.name,
                unit: metric.unit,
                fieldType: .number,
                stepSize: metric.step,
                zone: .general
            ))
        }

        // Race-result fields. Finish Place stays Number with a step of 1;
        // the three lap-time entries are Time-type with nil step size so
        // they enter through the TimePickerInput surface that Time
        // metrics already use elsewhere in the app.
        all.append(Spec(name: "Finish Place", unit: "", fieldType: .number, stepSize: 1, zone: .general))
        all.append(Spec(name: "Race Time", unit: "", fieldType: .time, stepSize: nil, zone: .general))
        all.append(Spec(name: "Average Lap Time", unit: "", fieldType: .time, stepSize: nil, zone: .general))
        all.append(Spec(name: "Fastest Lap Time", unit: "", fieldType: .time, stepSize: nil, zone: .general))

        return all
    }()
}
