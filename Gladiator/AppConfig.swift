//
//  AppConfig.swift
//  Gladiator
//

import Foundation

// Compile-time feature flags. Tools remain fully built and functional —
// these flags only gate the analytics card entry points so a tool can be
// hidden from release without ripping out its code. Flip a flag to true
// to surface its card again.
enum AppConfig {
    static let isMetricLogEnabled = false
    static let isCorrelationMatrixEnabled = false
    static let isPersonalBestsEnabled = false
    static let isPerformancePredictorEnabled = false
    static let isRaceEngineerEnabled = true
    static let isRaceEngineerV2Enabled = false
}
