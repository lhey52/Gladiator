//
//  PersonalBestsView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct PersonalBestsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\CustomField.sortOrder)])
    private var allFields: [CustomField]
    @Query(sort: [SortDescriptor(\Session.date, order: .reverse)])
    private var sessions: [Session]

    @State private var filter = AnalyticsFilterState()
    @State private var showingFilter: Bool = false
    @State private var isLoading: Bool = true

    private var filteredSessions: [Session] {
        filter.apply(to: sessions)
    }

    private var plottableFields: [CustomField] {
        allFields.filter { $0.fieldType.isPlottable }
    }

    var body: some View {
        if isLoading {
            AnalyticsLoadingView(
                toolName: "Personal Bests",
                sessionCount: sessions.count,
                onComplete: { isLoading = false }
            )
        } else {
            toolContent
        }
    }

    private var toolContent: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                content
            }
            .navigationTitle("Personal Bests")
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
    private var content: some View {
        if plottableFields.isEmpty {
            emptyState
        } else {
            bestsList
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "trophy")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.6))
            Text("ADD NUMBER OR TIME METRICS IN SETTINGS")
                .font(.system(size: 12, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var bestsList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ToolDescriptionCard(text: "Review your all-time best recorded value for every plottable metric. Time-based metrics highlight the lowest value; number-based metrics highlight the highest. Tap any row to open the session where the record was set.")
                ForEach(plottableFields) { field in
                    bestCard(for: field)
                }
            }
            .padding(20)
        }
    }

    private func bestCard(for field: CustomField) -> some View {
        let best = findBest(for: field)
        return Group {
            if let best {
                NavigationLink {
                    SessionDetailView(session: best.session)
                } label: {
                    bestRow(field: field, best: best)
                }
                .buttonStyle(.plain)
            } else {
                placeholderRow(field: field)
            }
        }
    }

    private func bestRow(field: CustomField, best: BestRecord) -> some View {
        HStack(spacing: 14) {
            trophyIcon

            VStack(alignment: .leading, spacing: 4) {
                Text(field.name.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(Theme.textSecondary)
                Text(best.displayValue)
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.accent)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(best.session.trackName.isEmpty ? "Untitled" : best.session.trackName)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                Text(Self.dateFormatter.string(from: best.session.date).uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.textTertiary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.accent.opacity(0.25), lineWidth: 1)
        )
    }

    private func placeholderRow(field: CustomField) -> some View {
        HStack(spacing: 14) {
            trophyIcon

            VStack(alignment: .leading, spacing: 4) {
                Text(field.name.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(Theme.textSecondary)
                Text("—")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.textTertiary)
            }

            Spacer()

            Text("NO DATA YET")
                .font(.system(size: 10, weight: .bold))
                .tracking(1)
                .foregroundColor(Theme.textTertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private var trophyIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.accent.opacity(0.12))
                .frame(width: 42, height: 42)
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.accent.opacity(0.4), lineWidth: 1)
                .frame(width: 42, height: 42)
            Image(systemName: "trophy.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.accent)
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM dd, yyyy"
        return f
    }()

    private struct BestRecord {
        let session: Session
        let value: Double
        let displayValue: String
    }

    private func findBest(for field: CustomField) -> BestRecord? {
        var best: BestRecord?
        let isTime = field.fieldType == .time
        for session in filteredSessions {
            guard let fv = session.fieldValues.first(where: { $0.fieldName == field.name }),
                  let val = Double(fv.value) else { continue }
            let isBetter: Bool
            if let current = best {
                isBetter = isTime ? val < current.value : val > current.value
            } else {
                isBetter = true
            }
            if isBetter {
                let display = isTime ? TimeFormatting.secondsToDisplay(val) : formatNumber(val)
                best = BestRecord(session: session, value: val, displayValue: display)
            }
        }
        return best
    }

    private func formatNumber(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }
}

#Preview {
    PersonalBestsView()
        .modelContainer(for: [Session.self, CustomField.self, FieldValue.self], inMemory: true)
}
