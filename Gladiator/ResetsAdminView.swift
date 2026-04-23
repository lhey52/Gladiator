//
//  ResetsAdminView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct ResetsAdminView: View {
    @Environment(\.modelContext) private var modelContext

    @AppStorage("sessionFormTipDismissed") private var sessionFormTipDismissed: Bool = false
    @AppStorage("dashboardTipDismissed") private var dashboardTipDismissed: Bool = false
    @AppStorage("dashboardDeviceTipDismissed") private var dashboardDeviceTipDismissed: Bool = false
    @AppStorage("settingsCustomizationTipDismissed") private var settingsCustomizationTipDismissed: Bool = false
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial: Bool = false

    @State private var pendingAction: ResetAction?

    private enum ResetAction: Identifiable {
        case tooltips
        case tutorial
        case sessions
        case metrics
        case tracks
        case vehicles
        case drivers

        var id: String {
            switch self {
            case .tooltips: return "tooltips"
            case .tutorial: return "tutorial"
            case .sessions: return "sessions"
            case .metrics: return "metrics"
            case .tracks: return "tracks"
            case .vehicles: return "vehicles"
            case .drivers: return "drivers"
            }
        }

        var title: String {
            switch self {
            case .tooltips: return "Reset Tooltips"
            case .tutorial: return "Reset Tutorial"
            case .sessions: return "Clear All Sessions"
            case .metrics: return "Clear All Metrics"
            case .tracks: return "Clear All Tracks"
            case .vehicles: return "Clear All Vehicles"
            case .drivers: return "Clear All Drivers"
            }
        }

        var message: String {
            switch self {
            case .tooltips:
                return "This will restore all dismissed tips. Continue?"
            case .tutorial:
                return "The first launch tutorial will show again the next time you open the app. Continue?"
            case .sessions:
                return "This will permanently delete every session and every recorded metric value. This cannot be undone."
            case .metrics:
                return "This will permanently delete every custom metric definition. Recorded values on existing sessions will remain but become unlabeled. This cannot be undone."
            case .tracks:
                return "This will permanently delete every saved track. Existing session track names will remain as strings. This cannot be undone."
            case .vehicles:
                return "This will permanently delete every saved vehicle. Existing session vehicle names will remain as strings. This cannot be undone."
            case .drivers:
                return "This will remove driver names from every saved vehicle but keep the vehicles intact. This cannot be undone."
            }
        }

        var confirmLabel: String {
            switch self {
            case .tooltips, .tutorial: return "Reset"
            default: return "Clear"
            }
        }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            List {
                Section {
                    resetButton(action: .tooltips, label: "Reset Tooltips")
                    resetButton(action: .tutorial, label: "Reset Tutorial")
                } header: {
                    sectionHeader("TIPS & TUTORIAL")
                }

                Section {
                    resetButton(action: .sessions, label: "Clear All Sessions")
                    resetButton(action: .metrics, label: "Clear All Metrics")
                    resetButton(action: .tracks, label: "Clear All Tracks")
                    resetButton(action: .vehicles, label: "Clear All Vehicles")
                    resetButton(action: .drivers, label: "Clear All Drivers")
                } header: {
                    sectionHeader("DATA")
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Resets")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            pendingAction?.title ?? "",
            isPresented: Binding(
                get: { pendingAction != nil },
                set: { if !$0 { pendingAction = nil } }
            ),
            presenting: pendingAction
        ) { action in
            Button("Cancel", role: .cancel) { pendingAction = nil }
            Button(action.confirmLabel, role: .destructive) { perform(action) }
        } message: { action in
            Text(action.message)
        }
    }

    private func resetButton(action: ResetAction, label: String) -> some View {
        Button {
            pendingAction = action
        } label: {
            Text(label)
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(.red)
                .padding(.vertical, 4)
        }
        .listRowBackground(Theme.surface)
        .listRowSeparatorTint(Theme.hairline)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .heavy))
            .tracking(1.8)
            .foregroundColor(Theme.accent)
    }

    private func perform(_ action: ResetAction) {
        switch action {
        case .tooltips:
            sessionFormTipDismissed = false
            dashboardTipDismissed = false
            dashboardDeviceTipDismissed = false
            settingsCustomizationTipDismissed = false
        case .tutorial:
            hasSeenTutorial = false
        case .sessions:
            deleteAll(Session.self)
        case .metrics:
            deleteAll(CustomField.self)
        case .tracks:
            deleteAll(Track.self)
        case .vehicles:
            deleteAll(Vehicle.self)
        case .drivers:
            clearDriversFromVehicles()
        }
        pendingAction = nil
    }

    private func deleteAll<T: PersistentModel>(_ type: T.Type) {
        guard let all = try? modelContext.fetch(FetchDescriptor<T>()) else { return }
        for item in all {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }

    private func clearDriversFromVehicles() {
        guard let vehicles = try? modelContext.fetch(FetchDescriptor<Vehicle>()) else { return }
        for vehicle in vehicles {
            let parts = Vehicle.split(name: vehicle.name)
            if !parts.driver.isEmpty {
                vehicle.name = parts.name
            }
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        ResetsAdminView()
    }
    .preferredColorScheme(.dark)
}
