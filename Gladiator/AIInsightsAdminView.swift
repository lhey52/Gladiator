//
//  AIInsightsAdminView.swift
//  Gladiator
//

import SwiftUI

struct AIInsightsAdminView: View {
    private let rows: [AdminInsightRow] = AdminInsightCatalog.allRows

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {
                    header
                    ForEach(rows) { row in
                        insightCard(row)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("AI Insights")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(Theme.accent)
            Text("INSIGHT CATALOG")
                .font(.system(size: 11, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.textSecondary)
            Spacer()
            Text("\(rows.count) ENTRIES")
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 2)
    }

    private func insightCard(_ row: AdminInsightRow) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(row.priorityLabel)
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(Theme.background)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Theme.accent))
                Text(row.name.uppercased())
                    .font(.system(size: 13, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.textPrimary)
                Spacer(minLength: 0)
            }

            labeledBlock(
                label: "CONDITION",
                text: row.condition,
                textColor: Theme.textPrimary,
                italic: false
            )

            labeledBlock(
                label: "MESSAGE",
                text: row.message,
                textColor: Theme.textSecondary,
                italic: true
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private func labeledBlock(label: String, text: String, textColor: Color, italic: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(Theme.accent)
            let base = Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(textColor)
            (italic ? base.italic() : base)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct AdminInsightRow: Identifiable {
    let id = UUID()
    let sortKey: Int
    let priorityLabel: String
    let name: String
    let condition: String
    let message: String
}

enum AdminInsightCatalog {
    static let allRows: [AdminInsightRow] = [
        AdminInsightRow(
            sortKey: 1,
            priorityLabel: "1",
            name: "Low Session Combos",
            condition: "Any (track, vehicle) combination has fewer than 5 recorded sessions.",
            message: "The following track and vehicle combinations have less than 5 sessions: [combos]. Add more sessions to generate additional AI insights and unlock most analytics tools for these combinations."
        ),
        AdminInsightRow(
            sortKey: 2,
            priorityLabel: "2",
            name: "Stale Combos",
            condition: "Any (track, vehicle) combination has had no new sessions for 30 or more days.",
            message: "You haven't added new sessions for these track and vehicle combinations in the last 30 days: [combos]. Consistent logging improves your analytics accuracy."
        ),
        AdminInsightRow(
            sortKey: 3,
            priorityLabel: "3 / 4",
            name: "Personal Best",
            condition: "Your most recent session at a (track, vehicle) combination sets a new highest or lowest ever recorded value for a plottable metric vs. prior sessions in the same combination.",
            message: "Your most recent session at [track] in [vehicle] recorded your [highest or lowest] ever [metric] at this track and vehicle combination: [value]."
        ),
        AdminInsightRow(
            sortKey: 5,
            priorityLabel: "5 – 8",
            name: "Correlation Detected",
            condition: "A pair of plottable metrics at a (track, vehicle) combination shows a strong or very strong positive or negative Pearson correlation across 5 or more sessions.",
            message: "[Strong or very strong] correlation detected at [track] in [vehicle]: higher values of [metric A] are [strongly or very strongly] correlated with [higher or lower] values of [metric B] across [n] sessions."
        ),
        AdminInsightRow(
            sortKey: 9,
            priorityLabel: "9 – 11",
            name: "Trend Direction",
            condition: "A plottable metric at a (track, vehicle) combination shows a clear improving, declining, or plateau direction across 5 or more recent sessions (plateau requires 10+).",
            message: "[Improving / Declining / Plateau] trend detected at [track] in [vehicle]: your [metric] has been trending in a [positive / negative / stable] direction over your last [n] sessions."
        ),
        AdminInsightRow(
            sortKey: 12,
            priorityLabel: "12",
            name: "Most Consistent Metric",
            condition: "At least one plottable metric has 5 or more recorded values at a (track, vehicle) combination; the metric with the lowest coefficient of variation wins.",
            message: "Your most consistently recorded metric at [track] in [vehicle] is [metric]. Strong consistency here gives you reliable data to work with."
        ),
        AdminInsightRow(
            sortKey: 13,
            priorityLabel: "13",
            name: "High Variance Warning",
            condition: "Any plottable metric at a (track, vehicle) combination has a coefficient of variation above 0.3.",
            message: "Your [metric] at [track] in [vehicle] shows high variability across sessions. Improving consistency here could improve your setup reliability."
        ),
        AdminInsightRow(
            sortKey: 14,
            priorityLabel: "14",
            name: "Data Gap Warning",
            condition: "Any metric is missing values in more than 50% of sessions at a (track, vehicle) combination that has 5 or more sessions.",
            message: "Several of your sessions at [track] in [vehicle] are missing values for [metric]. Completing this data would improve your analytics accuracy."
        ),
        AdminInsightRow(
            sortKey: 15,
            priorityLabel: "15",
            name: "Performance Predictor Nudge",
            condition: "A (track, vehicle) combination has 8 or more sessions each with 3 or more plottable metrics recorded, and the user has not yet opened the Performance Predictor tool.",
            message: "You have enough data at [track] in [vehicle] to run a Performance Predictor analysis. Head to Analytics to discover what influences your performance most."
        )
    ].sorted { $0.sortKey < $1.sortKey }
}

#Preview {
    NavigationStack {
        AIInsightsAdminView()
    }
    .preferredColorScheme(.dark)
}
