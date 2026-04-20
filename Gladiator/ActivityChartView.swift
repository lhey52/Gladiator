//
//  ActivityChartView.swift
//  Gladiator
//

import SwiftUI
import SwiftData
import Charts

struct ActivityChartView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\Session.date, order: .reverse)])
    private var sessions: [Session]

    @State private var filter = AnalyticsFilterState()
    @State private var showingFilter: Bool = false

    private var filteredSessions: [Session] {
        filter.apply(to: sessions)
    }

    private struct DayBucket: Identifiable {
        let id: Date
        let date: Date
        let count: Int
    }

    private var buckets: [DayBucket] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredSessions) { session in
            calendar.startOfDay(for: session.date)
        }
        return grouped
            .map { DayBucket(id: $0.key, date: $0.key, count: $0.value.count) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                mainContent
            }
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    FilterButton(isActive: filter.isActive) {
                        showingFilter = true
                    }
                }
            }
            .sheet(isPresented: $showingFilter) {
                FilterSheetView(filter: filter)
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var mainContent: some View {
        if filteredSessions.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(spacing: 20) {
                    chartSection
                    sessionCount
                }
                .padding(20)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "chart.bar")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.6))
            Text("NO SESSIONS MATCH FILTERS")
                .font(.system(size: 13, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SESSIONS OVER TIME")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.8)
                .foregroundColor(Theme.accent)

            Chart(buckets) { bucket in
                BarMark(
                    x: .value("Date", bucket.date, unit: .day),
                    y: .value("Sessions", bucket.count)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.accent, Theme.accent.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine().foregroundStyle(Theme.hairline)
                    AxisValueLabel()
                        .foregroundStyle(Theme.textTertiary)
                        .font(.system(size: 10, weight: .bold))
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine().foregroundStyle(Theme.hairline)
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .foregroundStyle(Theme.textTertiary)
                        .font(.system(size: 10, weight: .bold))
                }
            }
            .chartPlotStyle { plot in
                plot.border(Theme.textTertiary, width: 1)
            }
            .frame(height: 300)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private var sessionCount: some View {
        Text("Showing \(filteredSessions.count) session\(filteredSessions.count == 1 ? "" : "s")")
            .font(.system(size: 12, weight: .bold))
            .tracking(1)
            .foregroundColor(Theme.textTertiary)
            .frame(maxWidth: .infinity)
    }
}

#Preview {
    ActivityChartView()
        .modelContainer(for: [Session.self, CustomField.self, FieldValue.self, Track.self, Vehicle.self], inMemory: true)
}
