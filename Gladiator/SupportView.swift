//
//  SupportView.swift
//  Gladiator
//

import SwiftUI
import MessageUI

struct SupportView: View {
    @State private var showingMailCompose: Bool = false
    @State private var showingMailError: Bool = false

    private let supportEmail = "SUPPORT_EMAIL_PLACEHOLDER"
    private let privacyPolicyURL = URL(string: "PRIVACY_POLICY_URL_PLACEHOLDER")!
    private let termsOfUseURL = URL(string: "TERMS_OF_USE_URL_PLACEHOLDER")!

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    contactRow
                    privacyRow
                    termsRow
                }
                .padding(20)
                .padding(.top, 4)
            }
        }
        .navigationTitle("Support")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingMailCompose) {
            MailComposeView(recipient: supportEmail)
        }
        .alert("Mail Not Available", isPresented: $showingMailError) {
            Button("Copy Email") {
                UIPasteboard.general.string = supportEmail
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("No mail account is set up on this device. You can copy the support email address instead.")
        }
    }

    private var contactRow: some View {
        Button {
            if MFMailComposeViewController.canSendMail() {
                showingMailCompose = true
            } else if let mailto = URL(string: "mailto:\(supportEmail)"),
                      UIApplication.shared.canOpenURL(mailto) {
                UIApplication.shared.open(mailto)
            } else {
                showingMailError = true
            }
        } label: {
            settingsRow(
                icon: "envelope.fill",
                title: "CONTACT SUPPORT",
                subtitle: supportEmail
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

struct MailComposeView: UIViewControllerRepresentable {
    let recipient: String
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients([recipient])
        vc.setSubject("Gladiator Support")
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        SupportView()
    }
    .preferredColorScheme(.dark)
}
