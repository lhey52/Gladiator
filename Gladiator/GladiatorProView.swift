//
//  GladiatorProView.swift
//  Gladiator
//

import SwiftUI

struct GladiatorProView: View {
    @ObservedObject private var iap = IAPManager.shared
    @State private var showingPaywall: Bool = false
    @State private var showingRestoreAlert: Bool = false
    @State private var restoreAlertMessage: String = ""

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            List {
                NavigationLink(destination: GladiatorAIView()) {
                    Text("AI Insights")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                        .padding(.vertical, 4)
                }
                .listRowBackground(Theme.surface)
                .listRowSeparatorTint(Theme.hairline)

                upgradeRow
                restoreRow
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .tint(Theme.accent)

            if iap.isLoading {
                Color.black.opacity(0.5).ignoresSafeArea()
                ProgressView()
                    .tint(Theme.accent)
                    .scaleEffect(1.5)
            }
        }
        .navigationTitle("Gladiator Pro")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView()
        }
        .alert("Restore Purchases", isPresented: $showingRestoreAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(restoreAlertMessage)
        }
    }

    @ViewBuilder
    private var upgradeRow: some View {
        if iap.isProUser {
            HStack {
                Text("Pro Active")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(Theme.textSecondary)
                    .padding(.vertical, 4)
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.accent)
            }
            .contentShape(Rectangle())
            .listRowBackground(Theme.surface)
            .listRowSeparatorTint(Theme.hairline)
        } else {
            Button {
                showingPaywall = true
            } label: {
                HStack {
                    Text("Upgrade")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                        .padding(.vertical, 4)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .listRowBackground(Theme.surface)
            .listRowSeparatorTint(Theme.hairline)
        }
    }

    private var restoreRow: some View {
        Button {
            performRestore()
        } label: {
            HStack {
                Text("Restore Purchases")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(Theme.textPrimary)
                    .padding(.vertical, 4)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(iap.isLoading)
        .listRowBackground(Theme.surface)
        .listRowSeparatorTint(Theme.hairline)
    }

    private func performRestore() {
        Task {
            await iap.restorePurchases()
            if let message = iap.errorMessage {
                restoreAlertMessage = message
            } else if iap.isProUser {
                restoreAlertMessage = "Your Gladiator Pro subscription has been restored."
            } else {
                restoreAlertMessage = "No active purchases found to restore."
            }
            showingRestoreAlert = true
        }
    }
}

#Preview {
    NavigationStack {
        GladiatorProView()
    }
    .preferredColorScheme(.dark)
}
