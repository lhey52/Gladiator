//
//  SessionCustomizationView.swift
//  Gladiator
//

import SwiftUI

struct SessionCustomizationView: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            List {
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
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Session Customization")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SessionCustomizationView()
    }
    .preferredColorScheme(.dark)
}
