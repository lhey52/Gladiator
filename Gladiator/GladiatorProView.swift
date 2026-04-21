//
//  GladiatorProView.swift
//  Gladiator
//

import SwiftUI

struct GladiatorProView: View {
    private enum ProTab: String, CaseIterable, Identifiable {
        case ai = "Gladiator AI"

        var id: String { rawValue }

        var systemImage: String {
            switch self {
            case .ai: return "sparkles"
            }
        }
    }

    @State private var selectedTab: ProTab = .ai
    @AppStorage("aiInsightThreshold") private var insightThreshold: Int = 5

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                tabBar
                content
            }
        }
        .navigationTitle("Gladiator Pro")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ProTab.allCases) { tab in
                    tabChip(tab)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 14)
    }

    private func tabChip(_ tab: ProTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 11, weight: .bold))
                Text(tab.rawValue.uppercased())
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.2)
            }
            .foregroundColor(isSelected ? Theme.background : Theme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Capsule().fill(isSelected ? Theme.accent : Theme.surface))
            .overlay(Capsule().stroke(isSelected ? Theme.accent : Theme.hairline, lineWidth: 1))
            .shadow(color: isSelected ? Theme.accent.opacity(0.4) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab content

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .ai:
            gladiatorAIContent
        }
    }

    private var gladiatorAIContent: some View {
        ScrollView {
            VStack(spacing: 18) {
                thresholdCard
                noteCard
            }
            .padding(20)
        }
    }

    // MARK: - Threshold card

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
                    Text("INSIGHTS MAX")
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

    // MARK: - Technical note card

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

            Text("The Insight Extraction Threshold defines the maximum number of insights surfaced in the Analytics carousel per evaluation cycle. Insights are priority-ranked prior to selection, so increasing the threshold broadens coverage at the cost of admitting lower-ranked observations with diminishing analytical value. Lower values preserve signal quality; higher values maximize breadth.")
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
        GladiatorProView()
    }
    .preferredColorScheme(.dark)
}
