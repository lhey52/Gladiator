//
//  SettingsView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink(destination: DriverProfileView()) {
                    Text("Driver Profile")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                        .padding(.vertical, 4)
                }
                .listRowBackground(Theme.surface)
                .listRowSeparatorTint(Theme.hairline)

                NavigationLink(destination: AppearanceView()) {
                    Text("Appearance")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                        .padding(.vertical, 4)
                }
                .listRowBackground(Theme.surface)
                .listRowSeparatorTint(Theme.hairline)

                NavigationLink(destination: GladiatorProView()) {
                    Text("Gladiator Pro")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                        .padding(.vertical, 4)
                }
                .listRowBackground(Theme.surface)
                .listRowSeparatorTint(Theme.hairline)

                NavigationLink(destination: SessionCustomizationView()) {
                    Text("Session Customization")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                        .padding(.vertical, 4)
                }
                .listRowBackground(Theme.surface)
                .listRowSeparatorTint(Theme.hairline)

                NavigationLink(destination: GlossaryView()) {
                    Text("Glossary")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                        .padding(.vertical, 4)
                }
                .listRowBackground(Theme.surface)
                .listRowSeparatorTint(Theme.hairline)

                NavigationLink(destination: ExportShareView()) {
                    Text("Export & Share")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                        .padding(.vertical, 4)
                }
                .listRowBackground(Theme.surface)
                .listRowSeparatorTint(Theme.hairline)

                NavigationLink(destination: TrackCodeView()) {
                    Text("Racetrack Code")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                        .padding(.vertical, 4)
                }
                .listRowBackground(Theme.surface)
                .listRowSeparatorTint(Theme.hairline)

                NavigationLink(destination: ResetView()) {
                    Text("Reset")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                        .padding(.vertical, 4)
                }
                .listRowBackground(Theme.surface)
                .listRowSeparatorTint(Theme.hairline)

                NavigationLink(destination: SupportView()) {
                    Text("Support")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                        .padding(.vertical, 4)
                }
                .listRowBackground(Theme.surface)
                .listRowSeparatorTint(Theme.hairline)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .tint(Theme.accent)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [CustomField.self, FieldValue.self, Session.self], inMemory: true)
        .preferredColorScheme(.dark)
}
