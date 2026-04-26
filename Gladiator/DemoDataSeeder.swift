//
//  DemoDataSeeder.swift
//  Gladiator
//

import Foundation
import SwiftData

enum DemoDataSeeder {

    // MARK: - Demo tracks & vehicles

    private static let demoTracks = ["Track1", "Track2", "Track3"]
    private static let demoVehicles = ["Vehicle1"]

    // MARK: - Demo metrics

    private static let demoMetrics: [(name: String, type: FieldType)] = [
        ("Metric1", .number),
        ("Metric2", .number)
    ]

    // MARK: - Demo sessions

    private struct DemoSession {
        let trackName: String
        let vehicleName: String
        let daysAgo: Int
        let values: [String: String]
    }

    private static let demoSessions: [DemoSession] = [
        DemoSession(trackName: "Track1", vehicleName: "Vehicle1", daysAgo: 5, values: ["Metric1": "10", "Metric2": "40"]),
        DemoSession(trackName: "Track1", vehicleName: "Vehicle1", daysAgo: 4, values: ["Metric1": "15", "Metric2": "45"]),
        DemoSession(trackName: "Track1", vehicleName: "Vehicle1", daysAgo: 3, values: ["Metric1": "20", "Metric2": "50"]),
        DemoSession(trackName: "Track1", vehicleName: "Vehicle1", daysAgo: 2, values: ["Metric1": "25", "Metric2": "55"]),
        DemoSession(trackName: "Track1", vehicleName: "Vehicle1", daysAgo: 1, values: ["Metric1": "30", "Metric2": "55"]),
        DemoSession(trackName: "Track2", vehicleName: "Vehicle1", daysAgo: 35, values: [:])
    ]

    // MARK: - Seed

    static func seed(into context: ModelContext) {
        seedTracks(into: context)
        seedVehicles(into: context)
        seedMetrics(into: context)
        seedSessions(into: context)
    }

    // MARK: - Demo 2

    private static var demo2Metrics: [(name: String, type: FieldType, stepSize: Double?)] {
        [
            ("Race Time", .time, nil),
            (CustomField.combine(name: "Tire Pressure (FL)", unit: "PSI"), .number, 1),
            (CustomField.combine(name: "Tire Pressure (FR)", unit: "PSI"), .number, 1),
            (CustomField.combine(name: "Tire Pressure (BL)", unit: "PSI"), .number, 1),
            (CustomField.combine(name: "Tire Pressure (BR)", unit: "PSI"), .number, 1)
        ]
    }

    private struct Demo2Session {
        let daysAgo: Int
        let raceTimeSeconds: Double
        let pressureFL: Double
        let pressureFR: Double
        let pressureBL: Double
        let pressureBR: Double
    }

    private static let demo2Sessions: [Demo2Session] = [
        Demo2Session(daysAgo: 40, raceTimeSeconds: 91.2, pressureFL: 28.5, pressureFR: 30.0, pressureBL: 27.5, pressureBR: 31.0),
        Demo2Session(daysAgo: 39, raceTimeSeconds: 92.8, pressureFL: 31.0, pressureFR: 29.5, pressureBL: 32.0, pressureBR: 28.5),
        Demo2Session(daysAgo: 38, raceTimeSeconds: 89.4, pressureFL: 27.0, pressureFR: 28.5, pressureBL: 26.5, pressureBR: 29.0),
        Demo2Session(daysAgo: 37, raceTimeSeconds: 88.7, pressureFL: 30.0, pressureFR: 31.5, pressureBL: 29.5, pressureBR: 30.0),
        Demo2Session(daysAgo: 36, raceTimeSeconds: 93.1, pressureFL: 28.0, pressureFR: 27.5, pressureBL: 29.0, pressureBR: 28.0),
        Demo2Session(daysAgo: 35, raceTimeSeconds: 90.5, pressureFL: 32.0, pressureFR: 30.5, pressureBL: 31.5, pressureBR: 32.0),
        Demo2Session(daysAgo: 34, raceTimeSeconds: 91.8, pressureFL: 26.5, pressureFR: 28.0, pressureBL: 27.0, pressureBR: 27.5),
        Demo2Session(daysAgo: 33, raceTimeSeconds: 87.9, pressureFL: 29.5, pressureFR: 32.5, pressureBL: 31.0, pressureBR: 30.5),
        Demo2Session(daysAgo: 32, raceTimeSeconds: 92.3, pressureFL: 30.5, pressureFR: 28.0, pressureBL: 29.0, pressureBR: 31.5),
        Demo2Session(daysAgo: 31, raceTimeSeconds: 88.5, pressureFL: 28.0, pressureFR: 29.5, pressureBL: 28.5, pressureBR: 27.0),
        Demo2Session(daysAgo: 30, raceTimeSeconds: 91.0, pressureFL: 31.5, pressureFR: 31.0, pressureBL: 32.5, pressureBR: 30.0),
        Demo2Session(daysAgo: 29, raceTimeSeconds: 93.4, pressureFL: 27.5, pressureFR: 26.5, pressureBL: 28.0, pressureBR: 28.5),
        Demo2Session(daysAgo: 28, raceTimeSeconds: 89.5, pressureFL: 30.5, pressureFR: 32.0, pressureBL: 29.5, pressureBR: 31.5),
        Demo2Session(daysAgo: 27, raceTimeSeconds: 94.0, pressureFL: 29.0, pressureFR: 27.0, pressureBL: 30.5, pressureBR: 28.0),
        Demo2Session(daysAgo: 26, raceTimeSeconds: 88.2, pressureFL: 32.5, pressureFR: 30.0, pressureBL: 31.0, pressureBR: 32.5),
        Demo2Session(daysAgo: 25, raceTimeSeconds: 90.1, pressureFL: 28.5, pressureFR: 31.5, pressureBL: 27.5, pressureBR: 29.5),
        Demo2Session(daysAgo: 24, raceTimeSeconds: 91.6, pressureFL: 27.0, pressureFR: 29.0, pressureBL: 30.0, pressureBR: 27.5),
        Demo2Session(daysAgo: 23, raceTimeSeconds: 88.9, pressureFL: 31.5, pressureFR: 28.5, pressureBL: 32.0, pressureBR: 30.5),
        Demo2Session(daysAgo: 22, raceTimeSeconds: 92.5, pressureFL: 29.5, pressureFR: 31.0, pressureBL: 28.5, pressureBR: 30.0),
        Demo2Session(daysAgo: 21, raceTimeSeconds: 89.0, pressureFL: 26.5, pressureFR: 28.0, pressureBL: 26.0, pressureBR: 29.0),
        Demo2Session(daysAgo: 20, raceTimeSeconds: 90.3, pressureFL: 32.0, pressureFR: 31.5, pressureBL: 33.0, pressureBR: 30.0),
        Demo2Session(daysAgo: 19, raceTimeSeconds: 93.2, pressureFL: 28.5, pressureFR: 30.5, pressureBL: 27.5, pressureBR: 31.0),
        Demo2Session(daysAgo: 18, raceTimeSeconds: 87.8, pressureFL: 30.0, pressureFR: 26.5, pressureBL: 31.5, pressureBR: 28.5),
        Demo2Session(daysAgo: 17, raceTimeSeconds: 91.1, pressureFL: 29.5, pressureFR: 32.0, pressureBL: 28.0, pressureBR: 29.5),
        Demo2Session(daysAgo: 16, raceTimeSeconds: 89.7, pressureFL: 31.0, pressureFR: 30.5, pressureBL: 32.5, pressureBR: 31.5),
        Demo2Session(daysAgo: 15, raceTimeSeconds: 92.0, pressureFL: 27.5, pressureFR: 29.5, pressureBL: 28.0, pressureBR: 26.5),
        Demo2Session(daysAgo: 14, raceTimeSeconds: 90.8, pressureFL: 30.5, pressureFR: 28.0, pressureBL: 29.0, pressureBR: 30.5),
        Demo2Session(daysAgo: 13, raceTimeSeconds: 88.4, pressureFL: 32.5, pressureFR: 29.5, pressureBL: 31.0, pressureBR: 32.0),
        Demo2Session(daysAgo: 12, raceTimeSeconds: 91.9, pressureFL: 28.0, pressureFR: 31.0, pressureBL: 27.0, pressureBR: 28.5),
        Demo2Session(daysAgo: 11, raceTimeSeconds: 89.2, pressureFL: 29.0, pressureFR: 28.5, pressureBL: 32.0, pressureBR: 29.5),
        Demo2Session(daysAgo: 10, raceTimeSeconds: 92.8, pressureFL: 31.5, pressureFR: 32.5, pressureBL: 30.5, pressureBR: 31.0),
        Demo2Session(daysAgo: 9,  raceTimeSeconds: 90.5, pressureFL: 27.0, pressureFR: 29.5, pressureBL: 28.5, pressureBR: 27.5),
        Demo2Session(daysAgo: 8,  raceTimeSeconds: 89.5, pressureFL: 30.5, pressureFR: 31.0, pressureBL: 29.5, pressureBR: 32.0),
        Demo2Session(daysAgo: 7,  raceTimeSeconds: 93.0, pressureFL: 28.5, pressureFR: 27.0, pressureBL: 30.0, pressureBR: 28.0),
        Demo2Session(daysAgo: 6,  raceTimeSeconds: 88.6, pressureFL: 32.0, pressureFR: 30.0, pressureBL: 33.0, pressureBR: 31.5),
        Demo2Session(daysAgo: 5,  raceTimeSeconds: 91.5, pressureFL: 29.5, pressureFR: 31.5, pressureBL: 28.5, pressureBR: 30.5),
        Demo2Session(daysAgo: 4,  raceTimeSeconds: 90.0, pressureFL: 31.0, pressureFR: 28.5, pressureBL: 29.5, pressureBR: 31.0),
        Demo2Session(daysAgo: 3,  raceTimeSeconds: 87.5, pressureFL: 27.5, pressureFR: 32.0, pressureBL: 28.0, pressureBR: 27.0),
        Demo2Session(daysAgo: 2,  raceTimeSeconds: 91.3, pressureFL: 32.5, pressureFR: 29.0, pressureBL: 31.5, pressureBR: 30.0),
        Demo2Session(daysAgo: 1,  raceTimeSeconds: 89.8, pressureFL: 30.0, pressureFR: 31.5, pressureBL: 29.0, pressureBR: 30.5)
    ]

    static func seedDemo2(into context: ModelContext) {
        ensureDemo2Track(into: context)
        ensureDemo2Vehicle(into: context)
        seedDemo2Metrics(into: context)
        seedDemo2Sessions(into: context)
    }

    private static func ensureDemo2Track(into context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Track>())) ?? []
        if !existing.contains(where: { $0.name == "Track1" }) {
            context.insert(Track(name: "Track1"))
        }
    }

    private static func ensureDemo2Vehicle(into context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Vehicle>())) ?? []
        if !existing.contains(where: { $0.name == "Vehicle1" }) {
            context.insert(Vehicle(name: "Vehicle1"))
        }
    }

    private static func seedDemo2Metrics(into context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<CustomField>())) ?? []
        let existingNames = Set(existing.map { $0.name.lowercased() })
        let maxOrder = existing.map(\.sortOrder).max() ?? -1
        var nextOrder = maxOrder + 1
        for metric in demo2Metrics where !existingNames.contains(metric.name.lowercased()) {
            context.insert(CustomField(
                name: metric.name,
                fieldType: metric.type,
                sortOrder: nextOrder,
                stepSize: metric.stepSize
            ))
            nextOrder += 1
        }
    }

    private static func seedDemo2Sessions(into context: ModelContext) {
        let cal = Calendar.current
        for demo in demo2Sessions {
            guard let date = cal.date(byAdding: .day, value: -demo.daysAgo, to: .now) else { continue }
            let session = Session(
                date: date,
                trackName: "Track1",
                vehicleName: "Vehicle1",
                sessionType: .practice,
                notes: ""
            )
            context.insert(session)

            let pairs: [(name: String, type: FieldType, value: Double)] = [
                ("Race Time", .time, demo.raceTimeSeconds),
                (CustomField.combine(name: "Tire Pressure (FL)", unit: "PSI"), .number, demo.pressureFL),
                (CustomField.combine(name: "Tire Pressure (FR)", unit: "PSI"), .number, demo.pressureFR),
                (CustomField.combine(name: "Tire Pressure (BL)", unit: "PSI"), .number, demo.pressureBL),
                (CustomField.combine(name: "Tire Pressure (BR)", unit: "PSI"), .number, demo.pressureBR)
            ]

            for pair in pairs {
                let valueString = pair.type == .time
                    ? String(format: "%.3f", pair.value)
                    : String(format: "%.1f", pair.value)
                let fv = FieldValue(
                    fieldName: pair.name,
                    fieldType: pair.type,
                    value: valueString,
                    session: session
                )
                context.insert(fv)
            }
        }
    }

    private static func seedTracks(into context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Track>())) ?? []
        let existingNames = Set(existing.map(\.name))
        for name in demoTracks where !existingNames.contains(name) {
            context.insert(Track(name: name))
        }
    }

    private static func seedVehicles(into context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Vehicle>())) ?? []
        let existingNames = Set(existing.map(\.name))
        for name in demoVehicles where !existingNames.contains(name) {
            context.insert(Vehicle(name: name))
        }
    }

    private static func seedMetrics(into context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<CustomField>())) ?? []
        let existingNames = Set(existing.map { $0.name.lowercased() })
        let maxOrder = existing.map(\.sortOrder).max() ?? -1
        var nextOrder = maxOrder + 1
        for metric in demoMetrics where !existingNames.contains(metric.name.lowercased()) {
            context.insert(CustomField(name: metric.name, fieldType: metric.type, sortOrder: nextOrder))
            nextOrder += 1
        }
    }

    private static func seedSessions(into context: ModelContext) {
        let cal = Calendar.current
        for demo in demoSessions {
            guard let date = cal.date(byAdding: .day, value: -demo.daysAgo, to: .now) else { continue }
            let session = Session(
                date: date,
                trackName: demo.trackName,
                vehicleName: demo.vehicleName,
                sessionType: .practice,
                notes: ""
            )
            context.insert(session)

            for (fieldName, value) in demo.values {
                let fieldType = demoMetrics.first(where: { $0.name == fieldName })?.type ?? .number
                let fv = FieldValue(fieldName: fieldName, fieldType: fieldType, value: value, session: session)
                context.insert(fv)
            }
        }
    }
}
