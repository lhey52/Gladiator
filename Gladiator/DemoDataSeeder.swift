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
