//
//  AppearanceView.swift
//  Gladiator
//

import SwiftUI

struct AppearanceView: View {
    @AppStorage("showNewsTicker") private var showNewsTicker: Bool = true

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            List {
                Toggle(isOn: $showNewsTicker) {
                    Text("Show News Ticker")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                }
                .tint(Theme.accent)
                .padding(.vertical, 4)
                .listRowBackground(Theme.surface)
                .listRowSeparatorTint(Theme.hairline)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AppearanceView()
    }
    .preferredColorScheme(.dark)
}
