//
//  FeatureFlagsAdminView.swift
//  Gladiator
//

import SwiftUI

// Live editor for the feature flags exposed by AppConfig. Each toggle is
// bound to the same UserDefaults key (`ff.*`) that AppConfig's computed
// properties read from, so flipping a switch here is reflected by every
// `if AppConfig.isXxxEnabled { … }` consumer on its next render.
struct FeatureFlagsAdminView: View {
    @AppStorage(AppConfig.Key.metricLog) private var metricLog: Bool = AppConfig.Default.metricLog
    @AppStorage(AppConfig.Key.correlationMatrix) private var correlationMatrix: Bool = AppConfig.Default.correlationMatrix
    @AppStorage(AppConfig.Key.personalBests) private var personalBests: Bool = AppConfig.Default.personalBests
    @AppStorage(AppConfig.Key.raceEngineerV2) private var raceEngineerV2: Bool = AppConfig.Default.raceEngineerV2
    @AppStorage(AppConfig.Key.sessionMetrics) private var sessionMetrics: Bool = AppConfig.Default.sessionMetrics
    @AppStorage(AppConfig.Key.zoneSetup) private var zoneSetup: Bool = AppConfig.Default.zoneSetup
    @AppStorage(AppConfig.Key.vehicleStyle) private var vehicleStyle: Bool = AppConfig.Default.vehicleStyle
    @AppStorage(AppConfig.Key.pitGoals) private var pitGoals: Bool = AppConfig.Default.pitGoals
    @AppStorage(AppConfig.Key.pitReminders) private var pitReminders: Bool = AppConfig.Default.pitReminders

    @State private var showingResetConfirm: Bool = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            List {
                Section {
                    toggleRow(label: "Metric Log", isOn: $metricLog)
                    toggleRow(label: "Correlation Matrix", isOn: $correlationMatrix)
                    toggleRow(label: "Personal Bests", isOn: $personalBests)
                    toggleRow(label: "Race Engineer V2", isOn: $raceEngineerV2)
                } header: {
                    sectionHeader("Analytics Tools")
                }

                Section {
                    toggleRow(label: "Session Metrics", isOn: $sessionMetrics)
                    toggleRow(label: "Zone Setup", isOn: $zoneSetup)
                    toggleRow(label: "Vehicle Style", isOn: $vehicleStyle)
                } header: {
                    sectionHeader("Session Customization")
                }

                Section {
                    toggleRow(label: "Goals", isOn: $pitGoals)
                    toggleRow(label: "Reminders", isOn: $pitReminders)
                } header: {
                    sectionHeader("The Pit")
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Feature Flags")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            resetButton
        }
        .alert(
            "Reset all feature flags?",
            isPresented: $showingResetConfirm
        ) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) { resetAll() }
        } message: {
            Text("Every flag in this view will return to its default off state. This cannot be undone.")
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .heavy))
            .tracking(1.8)
            .foregroundColor(Theme.accent)
    }

    private func toggleRow(label: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(label)
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(Theme.textPrimary)
                .padding(.vertical, 4)
        }
        .tint(Theme.accent)
        .listRowBackground(Theme.surface)
        .listRowSeparatorTint(Theme.hairline)
    }

    private var resetButton: some View {
        Button {
            showingResetConfirm = true
        } label: {
            Text("Reset All to Default")
                .font(.system(size: 13, weight: .heavy))
                .tracking(1)
                .foregroundColor(Theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.surface)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Theme.hairline),
                    alignment: .top
                )
        }
        .buttonStyle(.plain)
    }

    private func resetAll() {
        metricLog = false
        correlationMatrix = false
        personalBests = false
        raceEngineerV2 = false
        sessionMetrics = false
        zoneSetup = false
        vehicleStyle = false
        pitGoals = false
        pitReminders = false
    }
}

#Preview {
    NavigationStack {
        FeatureFlagsAdminView()
    }
    .preferredColorScheme(.dark)
}
