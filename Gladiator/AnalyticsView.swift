//
//  AnalyticsView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct AnalyticsView: View {
    @Query(sort: [SortDescriptor(\Session.date, order: .reverse)])
    private var sessions: [Session]
    @Query(sort: [SortDescriptor(\Track.name)])
    private var tracks: [Track]
    @Query(sort: [SortDescriptor(\CustomField.sortOrder)])
    private var fields: [CustomField]
    @ObservedObject private var iap = IAPManager.shared
    @AppStorage("aiInsightThreshold") private var insightThreshold: Int = 5
    @AppStorage("aiInsightCollapsed") private var aiInsightCollapsed: Bool = false

    @State private var insightIndex: Int = 0
    @State private var showingPaywall: Bool = false

    private var insights: [AIInsight] {
        AIInsightsEngine.generate(
            sessions: sessions,
            tracks: tracks,
            fields: fields,
            maxInsights: insightThreshold
        )
    }

    private var hasMultipleInsights: Bool {
        insights.count > 1
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        aiInsightCard
                        aiInsightCollapseToggle

                        Text("TOOLS")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(2)
                            .foregroundColor(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 4)
                            .padding(.top, 6)

                        AnalyticsCard(
                            icon: "chart.dots.scatter",
                            title: "Scatter Plot",
                            description: "Plot any two metrics against each other"
                        ) {
                            ScatterPlotView()
                        }

                        AnalyticsCard(
                            icon: "list.bullet.rectangle",
                            title: "Metric Log",
                            description: "View all recorded values for any metric across your sessions"
                        ) {
                            MetricLogView()
                        }

                        AnalyticsCard(
                            icon: "function",
                            title: "Correlation Analysis",
                            description: "Find statistical relationships between metrics"
                        ) {
                            CorrelationView()
                        }

                        AnalyticsCard(
                            icon: "tablecells",
                            title: "Correlation Matrix",
                            description: "Heat map of correlations across all metric pairs"
                        ) {
                            CorrelationMatrixView()
                        }

                        AnalyticsCard(
                            icon: "arrow.left.arrow.right.square",
                            title: "Session Comparison",
                            description: "Compare metrics across sessions or time periods"
                        ) {
                            SessionComparisonView()
                        }

                        AnalyticsCard(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Trend Analysis",
                            description: "Track how metrics change over time"
                        ) {
                            TrendAnalysisView()
                        }

                        AnalyticsCard(
                            icon: "trophy.fill",
                            title: "Personal Bests",
                            description: "All-time best values across every metric"
                        ) {
                            PersonalBestsView()
                        }

                        AnalyticsCard(
                            icon: "target",
                            title: "Performance Predictor",
                            description: "Discover which setup combinations best predict your performance"
                        ) {
                            PerformancePredictorView()
                        }
                    }
                    .padding(20)
                    .padding(.top, 4)
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Text("Analytics")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        ProBadgeIfNeeded()
                    }
                }
            }
            .fullScreenCover(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    private var currentMessage: String {
        guard !insights.isEmpty else { return AIInsightsEngine.defaultMessage }
        let clamped = min(insightIndex, insights.count - 1)
        return insights[clamped].message
    }

    private var aiInsightCollapseToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                aiInsightCollapsed.toggle()
            }
        } label: {
            HStack(spacing: 5) {
                Text(aiInsightCollapsed ? "SHOW" : "HIDE")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.2)
                Image(systemName: aiInsightCollapsed ? "chevron.down" : "chevron.up")
                    .font(.system(size: 10, weight: .heavy))
            }
            .foregroundColor(Theme.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(aiInsightCollapsed ? "Expand AI Insight" : "Collapse AI Insight")
    }

    private var aiInsightCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.accent)
                Text("GLADIATOR AI (BETA)")
                    .font(.system(size: 13, weight: .heavy))
                    .tracking(2)
                    .foregroundColor(Theme.accent)
                Spacer()
            }

            if !aiInsightCollapsed {
                aiInsightBody
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.accent.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: Theme.accent.opacity(0.18), radius: 18)
        .contentShape(Rectangle())
        .onTapGesture {
            if !iap.isProUser { showingPaywall = true }
        }
        .animation(.easeInOut(duration: 0.25), value: insightIndex)
    }

    @ViewBuilder
    private var aiInsightBody: some View {
        VStack(spacing: 14) {
            ZStack {
                VStack(spacing: 10) {
                    Text(currentMessage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .id(insightIndex)

                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text("Always verify insights manually.")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(Theme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .blur(radius: iap.isProUser ? 0 : 6)

                if !iap.isProUser {
                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12, weight: .bold))
                            Text("UNLOCK PRO")
                                .font(.system(size: 12, weight: .heavy))
                                .tracking(1.5)
                        }
                        Text("7 DAY FREE TRIAL")
                            .font(.system(size: 10, weight: .heavy))
                            .tracking(1.2)
                            .foregroundColor(Theme.accent.opacity(0.8))
                    }
                    .foregroundColor(Theme.accent)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Theme.surface))
                    .overlay(Capsule().stroke(Theme.accent.opacity(0.5), lineWidth: 1))
                }
            }

            if iap.isProUser {
                insightNavigationPro
            } else {
                insightNavigationLocked
            }
        }
    }

    private var insightNavigationPro: some View {
        HStack(spacing: 16) {
            Spacer()
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    insightIndex = max(0, insightIndex - 1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(insightIndex > 0 ? Theme.accent : Theme.textTertiary)
            }
            .disabled(insightIndex <= 0)

            Text("\(min(insightIndex, max(insights.count, 1) - 1) + 1) of \(max(insights.count, 1))")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.textSecondary)

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    insightIndex = min(insights.count - 1, insightIndex + 1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(insightIndex < insights.count - 1 ? Theme.accent : Theme.textTertiary)
            }
            .disabled(insightIndex >= insights.count - 1)
            Spacer()
        }
    }

    private var insightNavigationLocked: some View {
        HStack(spacing: 16) {
            Spacer()
            Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.textTertiary)

            Text("\(min(insightIndex, max(insights.count, 1) - 1) + 1) of \(max(insights.count, 1))")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.textSecondary)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(insights.count > 1 ? Theme.accent : Theme.textTertiary)
            Spacer()
        }
    }
}

private struct AnalyticsCard<Destination: View>: View {
    let icon: String
    let title: String
    let description: String
    @ViewBuilder let destination: () -> Destination

    @State private var showingFullScreen: Bool = false

    var body: some View {
        Button { showingFullScreen = true } label: {
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
                    Text(description)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
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
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showingFullScreen) {
            destination()
        }
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: [Session.self, CustomField.self, FieldValue.self, Track.self], inMemory: true)
        .preferredColorScheme(.dark)
}
