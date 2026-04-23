//
//  SettingsView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("isAdminConsoleUnlocked") private var isAdminConsoleUnlocked: Bool = false
    @AppStorage("settingsCustomizationTipDismissed") private var customizationTipDismissed: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !customizationTipDismissed {
                    customizationTip
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 4)
                }
                settingsList
            }
            .background(Theme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var customizationTip: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.accent)
            Text("Use Session Customization to modify session tracks, metrics, vehicles, and drivers.")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
            Spacer()
            Button { customizationTipDismissed = true } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Theme.accent.opacity(0.12), radius: 10, y: 4)
    }

    private var settingsList: some View {
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

                if isAdminConsoleUnlocked {
                    NavigationLink(destination: AdminConsoleView()) {
                        Text("Admin Console ✳︎")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(Theme.textPrimary)
                            .padding(.vertical, 4)
                    }
                    .listRowBackground(Theme.surface)
                    .listRowSeparatorTint(Theme.hairline)
                }
            }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .tint(Theme.accent)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [CustomField.self, FieldValue.self, Session.self], inMemory: true)
        .preferredColorScheme(.dark)
}
