//
//  AppConfig.swift
//  Gladiator
//

import Foundation

// Runtime feature flags. Each flag is a computed property that reads from
// UserDefaults under a stable `ff.*` key — admin toggles in
// FeatureFlagsAdminView write through @AppStorage to the same key, so
// every consumer (`if AppConfig.isMetricLogEnabled { … }`, etc.) reflects
// the new value on its next render without changing the call sites. When
// no value has been written yet the flag falls back to the per-flag
// default in `Default`.
enum AppConfig {
    enum Key {
        static let metricLog = "ff.isMetricLogEnabled"
        static let correlationMatrix = "ff.isCorrelationMatrixEnabled"
        static let personalBests = "ff.isPersonalBestsEnabled"
        static let performancePredictor = "ff.isPerformancePredictorEnabled"
        static let raceEngineer = "ff.isRaceEngineerEnabled"
        static let raceEngineerV2 = "ff.isRaceEngineerV2Enabled"
        static let pitGoals = "ff.isPitGoalsEnabled"
        static let pitReminders = "ff.isPitRemindersEnabled"
        static let sessionMetrics = "ff.isSessionMetricsEnabled"
        static let zoneSetup = "ff.isZoneSetupEnabled"
        static let vehicleStyle = "ff.isVehicleStyleEnabled"
    }

    enum Default {
        static let metricLog = false
        static let correlationMatrix = false
        static let personalBests = false
        static let performancePredictor = false
        static let raceEngineer = true
        static let raceEngineerV2 = false
        static let pitGoals = false
        static let pitReminders = false
        static let sessionMetrics = false
        static let zoneSetup = false
        static let vehicleStyle = false
    }

    static var isMetricLogEnabled: Bool { read(Key.metricLog, fallback: Default.metricLog) }
    static var isCorrelationMatrixEnabled: Bool { read(Key.correlationMatrix, fallback: Default.correlationMatrix) }
    static var isPersonalBestsEnabled: Bool { read(Key.personalBests, fallback: Default.personalBests) }
    static var isPerformancePredictorEnabled: Bool { read(Key.performancePredictor, fallback: Default.performancePredictor) }
    static var isRaceEngineerEnabled: Bool { read(Key.raceEngineer, fallback: Default.raceEngineer) }
    static var isRaceEngineerV2Enabled: Bool { read(Key.raceEngineerV2, fallback: Default.raceEngineerV2) }
    static var isPitGoalsEnabled: Bool { read(Key.pitGoals, fallback: Default.pitGoals) }
    static var isPitRemindersEnabled: Bool { read(Key.pitReminders, fallback: Default.pitReminders) }
    static var isSessionMetricsEnabled: Bool { read(Key.sessionMetrics, fallback: Default.sessionMetrics) }
    static var isZoneSetupEnabled: Bool { read(Key.zoneSetup, fallback: Default.zoneSetup) }
    static var isVehicleStyleEnabled: Bool { read(Key.vehicleStyle, fallback: Default.vehicleStyle) }

    private static func read(_ key: String, fallback: Bool) -> Bool {
        UserDefaults.standard.object(forKey: key) as? Bool ?? fallback
    }
}
