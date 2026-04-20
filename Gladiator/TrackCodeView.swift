//
//  TrackCodeView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct TrackCodeView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var iap = IAPManager.shared
    @AppStorage("activeTrackCode") private var activeCode: String = ""

    @State private var inputCode: String = ""
    @State private var statusMessage: String = ""
    @State private var statusIsError: Bool = false
    @State private var showToast: Bool = false
    @State private var toastText: String = ""
    @FocusState private var inputFocused: Bool

    private var hasActiveCode: Bool {
        !activeCode.isEmpty
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
                .dismissKeyboardOnTap()

            ScrollView {
                VStack(spacing: 24) {
                    if hasActiveCode {
                        activeCodeCard
                    } else {
                        inputCard
                    }
                    if !statusMessage.isEmpty {
                        statusLabel
                    }
                }
                .padding(20)
                .padding(.top, 4)
            }

            if showToast {
                VStack {
                    Spacer()
                    ToastView(icon: "checkmark.circle.fill", text: toastText)
                        .transition(.opacity)
                        .padding(.bottom, 16)
                }
                .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showToast)
        .navigationTitle("Track Code")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var activeCodeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ACTIVE CODE")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.8)
                .foregroundColor(Theme.accent)

            HStack {
                Text(activeCode)
                    .font(.system(size: 20, weight: .heavy, design: .monospaced))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.accent)
            }

            Button(action: unlockCode) {
                Text("Unlock")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.red.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.red.opacity(0.4), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.accent.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: Theme.accent.opacity(0.12), radius: 10)
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ENTER CODE")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.8)
                .foregroundColor(Theme.accent)

            TextField(
                "",
                text: $inputCode,
                prompt: Text("Enter track code").foregroundColor(Theme.textTertiary)
            )
            .font(.system(size: 18, weight: .heavy))
            .foregroundColor(Theme.textPrimary)
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
            .focused($inputFocused)

            Button(action: lockCode) {
                    Text("Lock")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(Theme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(inputCode.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.textTertiary : Theme.accent)
                        )
                        .shadow(color: inputCode.trimmingCharacters(in: .whitespaces).isEmpty ? .clear : Theme.accent.opacity(0.4), radius: 10)
                }
                .buttonStyle(.plain)
                .disabled(inputCode.trimmingCharacters(in: .whitespaces).isEmpty)
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

    private var statusLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: statusIsError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(statusIsError ? .red : Theme.accent)
            Text(statusMessage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(statusIsError ? .red : Theme.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    private func lockCode() {
        inputFocused = false
        let result = TrackCodes.validate(inputCode)
        switch result {
        case .success(let action):
            let normalized = inputCode.trimmingCharacters(in: .whitespaces).uppercased()
            if action == .grantPro {
                activeCode = normalized
            }
            inputCode = ""
            statusMessage = "Code activated successfully"
            statusIsError = false
            applyAction(action)
        case .invalid:
            statusMessage = "Invalid code"
            statusIsError = true
        case .expired:
            statusMessage = "This code is no longer active"
            statusIsError = true
        }
    }

    private func unlockCode() {
        inputFocused = false
        activeCode = ""
        inputCode = ""
        statusMessage = ""
        iap.codeGrantedPro = false
    }

    private func applyAction(_ action: TrackCodeAction) {
        switch action {
        case .grantPro:
            iap.codeGrantedPro = true
        case .seedDemoData:
            DemoDataSeeder.seed(into: modelContext)
            showToastBriefly("Demo data loaded successfully")
        }
    }

    private func showToastBriefly(_ text: String) {
        toastText = text
        showToast = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            showToast = false
        }
    }
}

#Preview {
    NavigationStack {
        TrackCodeView()
    }
    .preferredColorScheme(.dark)
}
