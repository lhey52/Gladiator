//
//  SessionCustomizationView.swift
//  Gladiator
//

import SwiftUI

struct SessionCustomizationView: View {
    @AppStorage("sessionProgressBarEnabled") private var sessionProgressBarEnabled: Bool = true

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            List {
                Section {
                    NavigationLink(destination: CustomFieldsView()) {
                        Text("Metrics")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(Theme.textPrimary)
                            .padding(.vertical, 4)
                    }
                    .listRowBackground(Theme.surface)
                    .listRowSeparatorTint(Theme.hairline)

                    NavigationLink(destination: TracksView()) {
                        Text("Tracks")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(Theme.textPrimary)
                            .padding(.vertical, 4)
                    }
                    .listRowBackground(Theme.surface)
                    .listRowSeparatorTint(Theme.hairline)

                    NavigationLink(destination: VehicleView()) {
                        Text("Vehicles")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(Theme.textPrimary)
                            .padding(.vertical, 4)
                    }
                    .listRowBackground(Theme.surface)
                    .listRowSeparatorTint(Theme.hairline)
                } header: {
                    sectionHeader("Data")
                }

                Section {
                    Toggle(isOn: $sessionProgressBarEnabled) {
                        Text("Session Progress Bar")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(Theme.textPrimary)
                            .padding(.vertical, 4)
                    }
                    .tint(Theme.accent)
                    .listRowBackground(Theme.surface)
                    .listRowSeparatorTint(Theme.hairline)
                } header: {
                    sectionHeader("Form")
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Session Customization")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .heavy))
            .tracking(1.8)
            .foregroundColor(Theme.accent)
    }
}

#Preview {
    NavigationStack {
        SessionCustomizationView()
    }
    .preferredColorScheme(.dark)
}
