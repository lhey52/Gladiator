//
//  AdminConsoleView.swift
//  Gladiator
//

import SwiftUI

struct AdminConsoleView: View {
    @ObservedObject private var iap = IAPManager.shared

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    header

                    proOverrideCard

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

                    NavigationLink {
                        DemoSeederAdminView()
                    } label: {
                        consoleCard(
                            title: "Demo Seeder",
                            icon: "tray.and.arrow.down.fill",
                            subtitle: "Load curated demo data into the app for testing and showcase."
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        ResetsAdminView()
                    } label: {
                        consoleCard(
                            title: "Resets",
                            icon: "arrow.counterclockwise",
                            subtitle: "Reset tooltips and the first-launch tutorial, or clear sessions, metrics, tracks, vehicles, and drivers."
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

    private var proOverrideCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(Theme.accent)
                Text("PRO OVERRIDE")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(2)
                    .foregroundColor(Theme.accent)
                Spacer()
            }

            VStack(spacing: 0) {
                statusRow(
                    label: "Real Subscription",
                    value: iap.hasStoreKitSubscription ? "Active" : "Inactive",
                    highlight: iap.hasStoreKitSubscription
                )
                rowDivider
                toggleRow
                rowDivider
                statusRow(
                    label: "Effective Pro",
                    value: iap.isProUser ? "On" : "Off",
                    highlight: iap.isProUser
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.hairline, lineWidth: 1)
            )

            if iap.hasStoreKitSubscription {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text("Real subscription is active — toggle has no effect on Pro status.")
                        .font(.system(size: 11, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundColor(Theme.textTertiary)
                .padding(.horizontal, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.accent.opacity(0.25), lineWidth: 1.5)
        )
        .shadow(color: Theme.accent.opacity(0.1), radius: 8, y: 3)
    }

    private var toggleRow: some View {
        HStack(spacing: 10) {
            Text("Admin / Code Override")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
            Spacer(minLength: 12)
            Toggle("", isOn: $iap.codeGrantedPro)
                .labelsHidden()
                .tint(Theme.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func statusRow(label: String, value: String, highlight: Bool) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
            Spacer(minLength: 12)
            Text(value.uppercased())
                .font(.system(size: 12, weight: .heavy))
                .tracking(1)
                .foregroundColor(highlight ? Theme.accent : Theme.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Theme.hairline)
            .frame(height: 1)
            .padding(.leading, 14)
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
