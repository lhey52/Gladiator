//
//  ResetView.swift
//  Gladiator
//

import SwiftUI

struct ResetView: View {
    @AppStorage("sessionFormTipDismissed") private var sessionFormTipDismissed: Bool = false
    @AppStorage("dashboardTipDismissed") private var dashboardTipDismissed: Bool = false
    @AppStorage("dashboardDeviceTipDismissed") private var dashboardDeviceTipDismissed: Bool = false
    @AppStorage("settingsCustomizationTipDismissed") private var settingsCustomizationTipDismissed: Bool = false
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial: Bool = false
    @State private var showingTooltipsConfirm: Bool = false
    @State private var showingTutorialConfirm: Bool = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            List {
                Button {
                    showingTooltipsConfirm = true
                } label: {
                    Text("Reset Tooltips")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(.red)
                        .padding(.vertical, 4)
                }
                .listRowBackground(Theme.surface)
                .listRowSeparatorTint(Theme.hairline)

                Button {
                    showingTutorialConfirm = true
                } label: {
                    Text("Reset Tutorial")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(.red)
                        .padding(.vertical, 4)
                }
                .listRowBackground(Theme.surface)
                .listRowSeparatorTint(Theme.hairline)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Reset")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reset Tooltips", isPresented: $showingTooltipsConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                sessionFormTipDismissed = false
                dashboardTipDismissed = false
                dashboardDeviceTipDismissed = false
                settingsCustomizationTipDismissed = false
            }
        } message: {
            Text("This will restore all dismissed tips. Continue?")
        }
        .alert("Reset Tutorial", isPresented: $showingTutorialConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                hasSeenTutorial = false
            }
        } message: {
            Text("The first launch tutorial will show again the next time you open the app. Continue?")
        }
    }
}

#Preview {
    NavigationStack {
        ResetView()
    }
    .preferredColorScheme(.dark)
}
