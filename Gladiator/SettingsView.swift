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
                NavigationLink(destination: CustomFieldsView()) {
                    Text("Session Metrics")
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
