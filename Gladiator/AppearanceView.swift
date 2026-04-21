//
//  AppearanceView.swift
//  Gladiator
//

import SwiftUI

struct AppearanceView: View {
    @AppStorage("newsFeedEnabled") private var newsEnabled: Bool = true

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            List {
                Toggle(isOn: $newsEnabled) {
                    Text("News Feed")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                        .padding(.vertical, 4)
                }
                .tint(Theme.accent)
                .listRowBackground(Theme.surface)
                .listRowSeparatorTint(Theme.hairline)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: newsEnabled) { _, _ in
            Task { await NewsService.shared.refresh() }
        }
    }
}

#Preview {
    NavigationStack {
        AppearanceView()
    }
    .preferredColorScheme(.dark)
}
