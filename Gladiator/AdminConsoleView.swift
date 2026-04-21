//
//  AdminConsoleView.swift
//  Gladiator
//

import SwiftUI

struct AdminConsoleView: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    header

                    NavigationLink {
                        AIInsightsAdminView()
                    } label: {
                        consoleCard(
                            title: "Gladiator AI Insights",
                            icon: "sparkles",
                            subtitle: "Inspect every insight definition, condition, and message template."
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
        }
        .navigationTitle("Admin Console")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "wrench.adjustable.fill")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(Theme.accent)
            Text("DEBUG TOOLS")
                .font(.system(size: 11, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 2)
    }

    private func consoleCard(title: String, icon: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.accent.opacity(0.15))
                    .frame(width: 52, height: 52)
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.accent.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(Theme.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.system(size: 15, weight: .heavy))
                    .tracking(1.1)
                    .foregroundColor(Theme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.accent.opacity(0.25), lineWidth: 1.5)
        )
        .shadow(color: Theme.accent.opacity(0.1), radius: 8, y: 3)
    }
}

#Preview {
    NavigationStack {
        AdminConsoleView()
    }
    .preferredColorScheme(.dark)
}
