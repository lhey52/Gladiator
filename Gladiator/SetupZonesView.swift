//
//  SetupZonesView.swift
//  Gladiator
//

import SwiftUI

// Picker for which of the six setup zones appear on the New / Edit Session
// car diagram. Stores the disabled set (default empty = all enabled) under
// a single AppStorage key so any consumer — RaceCarDiagramView,
// AddSessionView's zone-navigation chevrons — can read it without having
// to be wired up to this view directly. Toggling here is purely a display
// preference: it does not delete any existing field assignments and has
// no effect on analytics, metrics customization, or saved sessions.
struct SetupZonesView: View {
    @AppStorage("disabledSetupZones") private var disabledZonesRaw: String = "Engine"

    private var disabledZones: Set<String> {
        Set(disabledZonesRaw.split(separator: ",").map(String.init).filter { !$0.isEmpty })
    }

    private func isEnabled(_ zone: CarZone) -> Bool {
        !disabledZones.contains(zone.rawValue)
    }

    private func setEnabled(_ enabled: Bool, for zone: CarZone) {
        var disabled = disabledZones
        if enabled {
            disabled.remove(zone.rawValue)
        } else {
            disabled.insert(zone.rawValue)
        }
        disabledZonesRaw = disabled.sorted().joined(separator: ",")
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            List {
                Section {
                    ForEach(CarZone.carZones) { zone in
                        Toggle(isOn: Binding(
                            get: { isEnabled(zone) },
                            set: { setEnabled($0, for: zone) }
                        )) {
                            Text(zone.displayName)
                                .font(.system(size: 15, weight: .heavy))
                                .foregroundColor(Theme.textPrimary)
                                .padding(.vertical, 4)
                        }
                        .tint(Theme.accent)
                        .listRowBackground(Theme.surface)
                        .listRowSeparatorTint(Theme.hairline)
                    }
                } header: {
                    Text("ZONES")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(1.8)
                        .foregroundColor(Theme.accent)
                } footer: {
                    Text("Toggle which zones appear on the New Session car diagram. Disabled zones are hidden from the diagram only — any metrics assigned to them, analytics, and saved sessions are untouched.")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.textTertiary)
                        .padding(.top, 8)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Setup Zones")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SetupZonesView()
    }
    .preferredColorScheme(.dark)
}
