//
//  DashboardViewModel.swift
//  Gladiator
//

import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {
    struct StatTile: Identifiable {
        let id = UUID()
        let label: String
        let value: String
        let unit: String
        let delta: String?
        let deltaPositive: Bool
    }

    struct RecentSession: Identifiable {
        let id = UUID()
        let track: String
        let date: String
        let bestLap: String
        let laps: Int
    }

    @Published var driverName: String = "DRIVER 01"
    @Published var nextEvent: String = "SILVERSTONE · SAT 14:00"
    @Published var sessionCount: Int = 127
    @Published var totalLaps: Int = 2_418

    @Published var headlineStat: StatTile = .init(
        label: "BEST LAP",
        value: "1:27",
        unit: "842",
        delta: "-0.214",
        deltaPositive: true
    )

    @Published var tiles: [StatTile] = [
        .init(label: "TOP SPEED", value: "312", unit: "KM/H", delta: "+4", deltaPositive: true),
        .init(label: "AVG LAP", value: "1:29.6", unit: "SEC", delta: "-0.08", deltaPositive: true),
        .init(label: "CONSISTENCY", value: "94", unit: "%", delta: "+2", deltaPositive: true),
        .init(label: "TIRE WEAR", value: "68", unit: "%", delta: "+5", deltaPositive: false)
    ]

    @Published var recent: [RecentSession] = [
        .init(track: "Silverstone GP", date: "APR 12", bestLap: "1:27.842", laps: 24),
        .init(track: "Spa-Francorchamps", date: "APR 05", bestLap: "2:03.115", laps: 18),
        .init(track: "Monza", date: "MAR 28", bestLap: "1:21.904", laps: 32)
    ]
}
