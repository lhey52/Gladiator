//
//  SupportView.swift
//  Gladiator
//

import SwiftUI

struct SupportView: View {
    @ObservedObject private var iap = IAPManager.shared

    private let supportEmail = "support@blackforestcompany.com"
    private let privacyPolicyURL = URL(string: "https://blackforestcompany.com/privacy-policy-gladiator/")!
    private let termsOfUseURL = URL(string: "https://blackforestcompany.com/tc-gladiator/")!
    private let reviewURL = URL(string: "https://apps.apple.com/app/idYOUR_APP_ID")!

    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    contactRow
                    featureRow
                    privacyRow
                    termsRow
                    reviewRow
                    restoreRow
                }
                .padding(20)
                .padding(.top, 4)
            }

            if iap.isLoading {
                Color.black.opacity(0.5).ignoresSafeArea()
                ProgressView()
                    .tint(Theme.accent)
                    .scaleEffect(1.5)
            }
        }
        .navigationTitle("Support")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Restore Purchases", isPresented: $showRestoreAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(restoreMessage)
        }
    }

    private var contactRow: some View {
        Button {
            openMailto(subject: "Gladiator Support")
        } label: {
            settingsRow(
                icon: "envelope.fill",
                title: "CONTACT SUPPORT",
                subtitle: nil
            )
        }
        .buttonStyle(.plain)
    }

    private var featureRow: some View {
        Button {
            openMailto(subject: "Gladiator App - Request a Feature")
        } label: {
            settingsRow(
                icon: "wand.and.stars",
                title: "REQUEST A FEATURE",
                subtitle: nil
            )
        }
        .buttonStyle(.plain)
    }

    private var restoreRow: some View {
        Button {
            Task {
                await iap.restorePurchases()
                if iap.isProUser {
                    restoreMessage = "Your Gladiator Pro purchase has been restored."
                } else {
                    restoreMessage = iap.errorMessage ?? "No active purchases found to restore."
                }
                showRestoreAlert = true
            }
        } label: {
            settingsRow(
                icon: "arrow.clockwise",
                title: "RESTORE PURCHASES",
                subtitle: nil
            )
        }
        .buttonStyle(.plain)
    }

    private var privacyRow: some View {
        Button {
            UIApplication.shared.open(privacyPolicyURL)
        } label: {
            settingsRow(
                icon: "lock.shield.fill",
                title: "PRIVACY POLICY",
                subtitle: nil
            )
        }
        .buttonStyle(.plain)
    }

    private var termsRow: some View {
        Button {
            UIApplication.shared.open(termsOfUseURL)
        } label: {
            settingsRow(
                icon: "doc.text.fill",
                title: "TERMS OF USE",
                subtitle: nil
            )
        }
        .buttonStyle(.plain)
    }

    private var reviewRow: some View {
        Button {
            UIApplication.shared.open(reviewURL)
        } label: {
            settingsRow(
                icon: "star.fill",
                title: "LEAVE A REVIEW",
                subtitle: nil
            )
        }
        .buttonStyle(.plain)
    }

    private func openMailto(subject: String) {
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        guard let url = URL(string: "mailto:\(supportEmail)?subject=\(encodedSubject)") else { return }
        UIApplication.shared.open(url)
    }

    private func settingsRow(icon: String, title: String, subtitle: String?) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.accent.opacity(0.12))
                    .frame(width: 42, height: 42)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Theme.accent.opacity(0.4), lineWidth: 1)
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(Theme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                }
            }

            Spacer()

            Image(systemName: "arrow.up.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        SupportView()
    }
    .preferredColorScheme(.dark)
}
