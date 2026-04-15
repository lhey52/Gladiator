//
//  SettingsView.swift
//  Gladiator
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 16) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(Theme.accent)
                    Text("SETTINGS")
                        .font(.system(size: 22, weight: .heavy))
                        .tracking(2)
                        .foregroundColor(Theme.textPrimary)
                    Text("Customize your fields and categories")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
