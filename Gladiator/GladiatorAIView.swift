//
//  GladiatorAIView.swift
//  Gladiator
//

import SwiftUI

struct GladiatorAIView: View {
    @AppStorage("aiInsightThreshold") private var insightThreshold: Int = 5

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    thresholdCard
                    noteCard
                }
                .padding(20)
            }
        }
        .navigationTitle("AI Insights")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var thresholdCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("INSIGHT EXTRACTION THRESHOLD")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.8)
                .foregroundColor(Theme.accent)

            HStack(alignment: .center, spacing: 12) {
                stepperButton(symbol: "minus", enabled: insightThreshold > 5) {
                    if insightThreshold > 5 { insightThreshold -= 1 }
                }

                Spacer(minLength: 0)

                VStack(spacing: 4) {
                    Text("\(insightThreshold)")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    Text("VALUE")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(1.5)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer(minLength: 0)

                stepperButton(symbol: "plus", enabled: insightThreshold < 10) {
                    if insightThreshold < 10 { insightThreshold += 1 }
                }
            }

            HStack {
                Text("MIN 5")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textTertiary)
                Spacer()
                Text("MAX 10")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.accent.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: Theme.accent.opacity(0.12), radius: 10)
    }

    private func stepperButton(symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(enabled ? Theme.accent : Theme.textTertiary)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Theme.surfaceElevated))
                .overlay(Circle().stroke(enabled ? Theme.accent.opacity(0.5) : Theme.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.accent)
                Text("TECHNICAL NOTE")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.8)
                    .foregroundColor(Theme.accent)
            }

            Text("The Insight Extraction Threshold controls how broadly the Analytics carousel surfaces insights per evaluation cycle. Insights are priority-ranked prior to selection, so raising the threshold broadens coverage at the cost of admitting lower-ranked observations with diminishing analytical value. Lower values preserve signal quality; higher values maximize breadth.")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
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
}

#Preview {
    NavigationStack {
        GladiatorAIView()
    }
    .preferredColorScheme(.dark)
}
