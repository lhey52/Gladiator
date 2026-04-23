//
//  PaywallView.swift
//  Gladiator
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var iap = IAPManager.shared

    var limitMessage: String? = nil

    @State private var selectedPlan: String = IAPManager.annualID

    private var annualProduct: Product? {
        iap.products.first { $0.id == IAPManager.annualID }
    }

    private var monthlyProduct: Product? {
        iap.products.first { $0.id == IAPManager.monthlyID }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    dismissButton
                    heroSection
                    featuresSection
                    pricingSection
                    ctaButton
                    restoreButton
                    legalText
                    Color.clear.frame(height: 16)
                }
                .padding(.horizontal, 24)
            }

            if iap.isLoading {
                Color.black.opacity(0.5).ignoresSafeArea()
                ProgressView()
                    .tint(Theme.accent)
                    .scaleEffect(1.5)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Dismiss

    private var dismissButton: some View {
        HStack {
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(Theme.surface)
                    .clipShape(Circle())
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(Theme.accent)
                .shadow(color: Theme.accent.opacity(0.5), radius: 16)

            Text("BECOME A CHAMPION")
                .font(.system(size: 24, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)

            Text("WITH GLADIATOR PRO")
                .font(.system(size: 24, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.accent)

            Text("Unlock the full power of your racing data")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)

            if let limitMessage {
                Text(limitMessage)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundColor(Theme.accent)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            featureRow("sparkles", "AI Insights & Recommendations")
            featureRow("function", "Correlation Analysis & Other Pro Analytics Tools")
            featureRow("square.and.arrow.up", "Export & Share Data with Other Drivers")
            featureRow("infinity", "Unlimited Data Storage")
            featureRow("clock.badge.checkmark", "7-Day Free Trial — Cancel Anytime")
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface)
        )
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.accent)
            Text(text)
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(Theme.textPrimary)
            Spacer()
        }
    }

    // MARK: - Pricing

    private var pricingSection: some View {
        VStack(spacing: 12) {
            planCard(
                id: IAPManager.annualID,
                title: "ANNUAL",
                price: annualProduct?.displayPrice ?? "$399.99/year",
                subtitle: annualProduct.map { "\(formatMonthlyEquivalent($0))/month" } ?? "$33.33/month",
                badge: "BEST VALUE"
            )
            planCard(
                id: IAPManager.monthlyID,
                title: "MONTHLY",
                price: monthlyProduct?.displayPrice ?? "$49.99/month",
                subtitle: nil,
                badge: nil
            )
        }
    }

    private func planCard(id: String, title: String, price: String, subtitle: String?, badge: String?) -> some View {
        let isSelected = selectedPlan == id
        return Button { selectedPlan = id } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 13, weight: .heavy))
                            .tracking(1.5)
                            .foregroundColor(isSelected ? Theme.accent : Theme.textSecondary)
                        if let badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .heavy))
                                .tracking(1)
                                .foregroundColor(Theme.background)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Theme.accent))
                        }
                    }
                    Text(price)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.textSecondary)
                    }
                    Text("One time 7-day free trial included")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.accent.opacity(0.8))
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(isSelected ? Theme.accent : Theme.textTertiary, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.background)
                    }
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Theme.accent : Theme.hairline, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? Theme.accent.opacity(0.2) : .clear, radius: 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - CTA

    private var ctaButton: some View {
        VStack(spacing: 10) {
            if let error = iap.errorMessage {
                Text(error)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task {
                    guard let product = iap.products.first(where: { $0.id == selectedPlan }) else { return }
                    await iap.purchase(product)
                    if iap.isProUser { dismiss() }
                }
            } label: {
                Text("Start Free Trial")
                    .font(.system(size: 16, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Theme.accent)
                    )
                    .shadow(color: Theme.accent.opacity(0.5), radius: 16)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button {
            Task {
                await iap.restorePurchases()
                if iap.isProUser { dismiss() }
            }
        } label: {
            Text("Restore Purchases")
                .font(.system(size: 13, weight: .heavy))
                .foregroundColor(Theme.textSecondary)
        }
    }

    // MARK: - Legal

    private var legalText: some View {
        Text(selectedPlan == IAPManager.annualID
             ? "Cancel anytime. Billed annually after free trial ends."
             : "Cancel anytime. Billed monthly after free trial ends.")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(Theme.textTertiary)
            .multilineTextAlignment(.center)
    }

    // MARK: - Helpers

    private func formatMonthlyEquivalent(_ product: Product) -> String {
        let annual = product.price
        let monthly = annual / 12
        return monthly.formatted(.currency(code: product.priceFormatStyle.currencyCode ?? "USD"))
    }
}

#Preview {
    PaywallView()
}
