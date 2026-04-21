//
//  AppearanceView.swift
//  Gladiator
//

import SwiftUI

struct AppearanceView: View {
    @AppStorage("newsFeedEnabled") private var newsEnabled: Bool = true
    @AppStorage("newsTickerEnabled") private var newsTickerEnabled: Bool = true
    @AppStorage("newsTickerPreDisableState") private var newsTickerPreDisableState: Bool = true

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

                Toggle(isOn: $newsTickerEnabled) {
                    Text("News Ticker")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(newsEnabled ? Theme.textPrimary : Theme.textTertiary)
                        .padding(.vertical, 4)
                }
                .tint(Theme.accent)
                .disabled(!newsEnabled)
                .listRowBackground(Theme.surface)
                .listRowSeparatorTint(Theme.hairline)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: newsEnabled) { _, newValue in
            if newValue {
                newsTickerEnabled = newsTickerPreDisableState
            } else {
                newsTickerPreDisableState = newsTickerEnabled
                newsTickerEnabled = false
            }
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
