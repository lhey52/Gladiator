//
//  DemoDataSeeder.swift
//  Gladiator
//

import Foundation
import SwiftData

// Demo 1: 40 sessions at Seekonk Speedway with Vehicle One, one per
// day going back 40 days, alternating Practice → Qualifying → Race.
// Every session writes a realistic-looking value for each metric in
// DefaultMetricsLoader (loaded automatically before sessions seed),
// with a small deterministic skip pattern that omits ~6% of values
// to mimic incomplete real-world logging. Generation is fully
// deterministic — the same 40 sessions are produced every run.
enum DemoDataSeeder {

    private static let trackName = "Seekonk Speedway"
    private static let vehicleName = "Vehicle One"
    private static let sessionCount = 40

    static func seedDemo1(into context: ModelContext) {
        // DefaultMetricsLoader.load is idempotent — safe even if the
        // user has already loaded metrics manually or via first-launch.
        DefaultMetricsLoader.load(into: context)
        ensureTrack(into: context)
        ensureVehicle(into: context)
        seedSessions(into: context)
    }

    private static func ensureTrack(into context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Track>())) ?? []
        if !existing.contains(where: { $0.name == trackName }) {
            context.insert(Track(name: trackName))
        }
    }

    private static func ensureVehicle(into context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Vehicle>())) ?? []
        if !existing.contains(where: { $0.name == vehicleName }) {
            context.insert(Vehicle(name: vehicleName))
        }
    }

    // MARK: - Metric profiles

    // One profile per default metric. `base + amplitude * sin(...)`
    // gives the per-session value; `period` and `phase` are spread so
    // related corners drift relative to each other instead of moving
    // in lockstep. `precision` is the decimal count for Number metrics
    // and is ignored for Time (always %.3f raw seconds).
    private struct Profile {
        let zone: CarZone
        let name: String
        let unit: String
        let fieldType: FieldType
        let base: Double
        let amplitude: Double
        let period: Double
        let phase: Double
        let precision: Int
    }

    private static let profiles: [Profile] = {
        var out: [Profile] = []

        // Tire zones: each corner gets a phase offset so the four
        // corners' Hot Pressures (etc.) are correlated but not identical.
        let tireZones: [(zone: CarZone, phaseOffset: Double)] = [
            (.flTire, 0.0),
            (.frTire, 0.7),
            (.blTire, 1.4),
            (.brTire, 2.1)
        ]
        for tz in tireZones {
            out.append(Profile(zone: tz.zone, name: "Cold Tire Pressure", unit: "PSI",
                fieldType: .number, base: 28.0, amplitude: 1.5,
                period: 9, phase: tz.phaseOffset, precision: 1))
            out.append(Profile(zone: tz.zone, name: "Hot Tire Pressure", unit: "PSI",
                fieldType: .number, base: 33.5, amplitude: 1.8,
                period: 8, phase: tz.phaseOffset + 0.3, precision: 1))
            out.append(Profile(zone: tz.zone, name: "Shock Travel", unit: "inches",
                fieldType: .number, base: 2.2, amplitude: 0.4,
                period: 11, phase: tz.phaseOffset + 1.0, precision: 1))
            out.append(Profile(zone: tz.zone, name: "Inside Tire Temp", unit: "degrees F",
                fieldType: .number, base: 205, amplitude: 12,
                period: 7, phase: tz.phaseOffset + 0.5, precision: 0))
            out.append(Profile(zone: tz.zone, name: "Middle Tire Temp", unit: "degrees F",
                fieldType: .number, base: 198, amplitude: 10,
                period: 7, phase: tz.phaseOffset + 1.1, precision: 0))
            out.append(Profile(zone: tz.zone, name: "Outside Tire Temp", unit: "degrees F",
                fieldType: .number, base: 192, amplitude: 11,
                period: 7, phase: tz.phaseOffset + 1.7, precision: 0))
        }

        let chassis: [(name: String, unit: String, base: Double, amp: Double, period: Double, phase: Double, precision: Int)] = [
            ("X-Member Tabs",     "inches",  1.5,  0.4, 9,  0.0, 1),
            ("Swaybar Rds",       "inches",  0.8,  0.5, 7,  0.4, 1),
            ("Rear Stagger",      "inches",  2.0,  0.4, 11, 0.8, 1),
            ("Front Stagger",     "inches",  1.0,  0.3, 11, 1.2, 1),
            ("Trailing Arm Adj",  "inches",  0.25, 0.2, 13, 1.6, 1),
            ("Camber Shim Adj",   "inches",  0.15, 0.1, 13, 2.0, 1),
            ("Spring Rubber Adj", "inches",  0.30, 0.2, 13, 2.4, 1),
            ("Top Link",          "degrees", 0.0,  2.0, 9,  2.8, 1)
        ]
        for c in chassis {
            out.append(Profile(zone: .chassis, name: c.name, unit: c.unit,
                fieldType: .number, base: c.base, amplitude: c.amp,
                period: c.period, phase: c.phase, precision: c.precision))
        }

        // General: weather + race results. Lap times are stored as raw
        // seconds (matching the contract used by the rest of the app).
        out.append(Profile(zone: .general, name: "Outside Temp", unit: "degrees F",
            fieldType: .number, base: 72, amplitude: 14, period: 12, phase: 0.0, precision: 0))
        out.append(Profile(zone: .general, name: "Humidity", unit: "%",
            fieldType: .number, base: 58, amplitude: 18, period: 9, phase: 1.2, precision: 0))
        out.append(Profile(zone: .general, name: "Finish Place", unit: "",
            fieldType: .number, base: 7.5, amplitude: 5.5, period: 6, phase: 0.3, precision: 0))
        out.append(Profile(zone: .general, name: "Race Time", unit: "",
            fieldType: .time, base: 1815, amplitude: 90, period: 8, phase: 0.7, precision: 3))
        out.append(Profile(zone: .general, name: "Average Lap Time", unit: "",
            fieldType: .time, base: 13.95, amplitude: 0.45, period: 7, phase: 0.9, precision: 3))
        out.append(Profile(zone: .general, name: "Fastest Lap Time", unit: "",
            fieldType: .time, base: 13.55, amplitude: 0.35, period: 7, phase: 1.4, precision: 3))

        return out
    }()

    // MARK: - Generation

    private static func value(profile: Profile, sessionIndex i: Int) -> Double {
        let theta = Double(i) * .pi * 2.0 / profile.period + profile.phase
        let primary = sin(theta) * profile.amplitude
        // Secondary harmonic so plotted series don't read as a clean sine.
        let harmonic = sin(theta * 1.7 + 0.6) * profile.amplitude * 0.25
        return profile.base + primary + harmonic
    }

    private static func clamp(profile: Profile, value v: Double) -> Double {
        if profile.zone == .general && profile.name == "Finish Place" {
            return min(max(v, 1), 18)
        }
        if profile.fieldType == .time {
            return max(v, 0.001)
        }
        return v
    }

    private static func format(profile: Profile, value v: Double) -> String {
        if profile.fieldType == .time {
            return String(format: "%.3f", v)
        }
        switch profile.precision {
        case 0: return String(format: "%.0f", v)
        case 1: return String(format: "%.1f", v)
        default: return String(format: "%.\(profile.precision)f", v)
        }
    }

    // FNV-1a 64. Swift's String.hashValue is randomized per process, so
    // a stable hash is needed for the skip pattern to be deterministic
    // across runs and devices.
    private static func stableHash(_ string: String) -> UInt64 {
        var h: UInt64 = 14695981039346656037
        for byte in string.utf8 {
            h ^= UInt64(byte)
            h = h &* 1099511628211
        }
        return h
    }

    private static func shouldSkip(profile: Profile, sessionIndex i: Int) -> Bool {
        let key = "\(i)|\(profile.zone.rawValue)|\(profile.name)"
        // ~6% of (session, metric) pairs get omitted.
        return stableHash(key) % 17 == 0
    }

    private static func sessionType(for index: Int) -> SessionType {
        switch index % 3 {
        case 0: return .practice
        case 1: return .qualifying
        default: return .race
        }
    }

    private static func seedSessions(into context: ModelContext) {
        let cal = Calendar.current
        for i in 0..<sessionCount {
            // i = 0 → yesterday, i = 39 → 40 days ago.
            let daysAgo = i + 1
            guard let date = cal.date(byAdding: .day, value: -daysAgo, to: .now) else { continue }
            let session = Session(
                date: date,
                trackName: trackName,
                vehicleName: vehicleName,
                sessionType: sessionType(for: i),
                notes: ""
            )
            context.insert(session)

            for profile in profiles where !shouldSkip(profile: profile, sessionIndex: i) {
                let raw = clamp(profile: profile, value: value(profile: profile, sessionIndex: i))
                let stored = format(profile: profile, value: raw)
                let combined = CustomField.combine(name: profile.name, unit: profile.unit)
                let prefixed = CustomField.applyPrefix(to: combined, zone: profile.zone)
                let fv = FieldValue(
                    fieldName: prefixed,
                    fieldType: profile.fieldType,
                    value: stored,
                    session: session
                )
                context.insert(fv)
            }
        }
    }
}
