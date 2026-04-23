//
//  DataTransferTutorialView.swift
//  Gladiator
//

import SwiftUI

struct DataTransferTutorialView: View {
    @Environment(\.dismiss) private var dismiss

    private let steps: [DataTransferTutorialStep] = [
        DataTransferTutorialStep(
            number: 1,
            icon: "square.and.arrow.up",
            title: "Send the File",
            body: "Tap the share button and choose Email or AirDrop to send your Gladiator data file to another device."
        ),
        DataTransferTutorialStep(
            number: 2,
            icon: "hand.tap.fill",
            title: "Open the File",
            body: "On the receiving device, tap the .gladiator file when it arrives."
        ),
        DataTransferTutorialStep(
            number: 3,
            icon: "ellipsis.circle",
            title: "Find More Options",
            body: "iOS will show a list of apps that can open the file. If Gladiator is not visible, scroll right and tap More."
        ),
        DataTransferTutorialStep(
            number: 4,
            icon: "apps.iphone",
            title: "Select Gladiator",
            body: "Scroll through the list to find Gladiator and select it."
        ),
        DataTransferTutorialStep(
            number: 5,
            icon: "checkmark.circle.fill",
            title: "Confirm Import",
            body: "Gladiator will open and show a confirmation prompt to import the data."
        ),
        DataTransferTutorialStep(
            number: 6,
            icon: "exclamationmark.triangle.fill",
            title: "About Duplicates",
            body: "Important: Duplicate sessions will not be excluded. If the receiving device already has some of the same sessions they will be imported again as duplicates."
        )
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        header
                        ForEach(steps) { step in
                            stepCard(step)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("How to Share & Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Theme.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.up.doc.on.clipboard")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(Theme.accent)
            Text("TRANSFER YOUR DATA")
                .font(.system(size: 11, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 2)
    }

    private func stepCard(_ step: DataTransferTutorialStep) -> some View {
        HStack(alignment: .top, spacing: 14) {
            numberBadge(step.number)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: step.icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.accent)
                    Text("STEP \(step.number)")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(1.5)
                        .foregroundColor(Theme.accent)
                }
                Text(step.title)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(Theme.textPrimary)
                Text(step.body)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private func numberBadge(_ number: Int) -> some View {
        ZStack {
            Circle()
                .fill(Theme.accent.opacity(0.15))
                .frame(width: 44, height: 44)
            Circle()
                .stroke(Theme.accent.opacity(0.5), lineWidth: 1.5)
                .frame(width: 44, height: 44)
            Text("\(number)")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.accent)
        }
    }
}

private struct DataTransferTutorialStep: Identifiable {
    let id = UUID()
    let number: Int
    let icon: String
    let title: String
    let body: String
}

#Preview {
    DataTransferTutorialView()
        .preferredColorScheme(.dark)
}
