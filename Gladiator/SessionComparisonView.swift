//
//  SessionComparisonView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct SessionComparisonView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\CustomField.sortOrder)])
    private var allFields: [CustomField]
    @Query(sort: [SortDescriptor(\Session.date, order: .reverse)])
    private var sessions: [Session]

    @State private var mode: ComparisonMode = .session
    @State private var sessionA: Session?
    @State private var sessionB: Session?
    @State private var yearA: Int = Calendar.current.component(.year, from: .now)
    @State private var yearB: Int = Calendar.current.component(.year, from: .now) - 1
    @State private var monthA: Date = .now
    @State private var monthB: Date = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @State private var customStartA: Date = Calendar.current.date(byAdding: .month, value: -2, to: .now) ?? .now
    @State private var customEndA: Date = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @State private var customStartB: Date = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @State private var customEndB: Date = .now
    @State private var showingPickerA: Bool = false
    @State private var showingPickerB: Bool = false
    @State private var higherIsBetter: [String: Bool] = [:]
    @State private var filter = AnalyticsFilterState()
    @State private var showingFilter: Bool = false
    @State private var isLoading: Bool = true

    private var plottableFields: [CustomField] {
        allFields.filter { $0.fieldType.isPlottable }
    }

    private var filteredSessions: [Session] {
        filter.apply(to: sessions)
    }

    private var availableYears: [Int] {
        let years = Set(filteredSessions.map { Calendar.current.component(.year, from: $0.date) })
        return years.sorted(by: >)
    }

    var body: some View {
        if isLoading {
            AnalyticsLoadingView(
                toolName: "Session Comparison",
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
                mainContent
            }
            .navigationTitle("Compare")
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

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                ToolDescriptionCard(text: "Compare two sessions or two time periods side by side to see how individual metrics differ. Choose a mode — Session, Year, Month, or Custom Range — then select both sides. The better value for each metric is highlighted in orange.")
                modePicker
                selectors
                results
            }
            .padding(20)
        }
    }

    // MARK: - Mode picker

    private var modePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ComparisonMode.allCases) { m in
                    Button {
                        mode = m
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: m.icon)
                                .font(.system(size: 10, weight: .bold))
                            Text(m.shortLabel)
                                .font(.system(size: 10, weight: .heavy))
                                .tracking(1)
                        }
                        .foregroundColor(mode == m ? Theme.background : Theme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            Capsule().fill(mode == m ? Theme.accent : Theme.surface)
                        )
                        .overlay(
                            Capsule().stroke(mode == m ? Theme.accent : Theme.hairline, lineWidth: 1)
                        )
                        .shadow(color: mode == m ? Theme.accent.opacity(0.4) : .clear, radius: 8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Selectors

    @ViewBuilder
    private var selectors: some View {
        switch mode {
        case .session: sessionSelectors
        case .year: yearSelectors
        case .month: monthSelectors
        case .custom: customSelectors
        }
    }

    private var sessionSelectors: some View {
        HStack(spacing: 10) {
            sessionButton(label: "A", session: sessionA) { showingPickerA = true }
                .sheet(isPresented: $showingPickerA) {
                    SessionPickerView(title: "Session A") { sessionA = $0 }
                }
            sessionButton(label: "B", session: sessionB) { showingPickerB = true }
                .sheet(isPresented: $showingPickerB) {
                    SessionPickerView(title: "Session B") { sessionB = $0 }
                }
        }
    }

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM dd"
        return f
    }()

    private func sessionButton(label: String, session: Session?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.background)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Theme.accent))
                if let session {
                    Text(session.trackName.isEmpty ? "Untitled" : session.trackName)
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    Text(Self.shortDateFormatter.string(from: session.date).uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundColor(Theme.textTertiary)
                } else {
                    Text("SELECT SESSION")
                        .font(.system(size: 12, weight: .heavy))
                        .tracking(1)
                        .foregroundColor(Theme.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var yearSelectors: some View {
        HStack(spacing: 10) {
            periodPicker(label: "A") {
                Picker("", selection: $yearA) {
                    ForEach(availableYears, id: \.self) { y in
                        Text(String(y)).tag(y)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.accent)
            } display: {
                Text(String(yearA))
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
            }
            periodPicker(label: "B") {
                Picker("", selection: $yearB) {
                    ForEach(availableYears, id: \.self) { y in
                        Text(String(y)).tag(y)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.accent)
            } display: {
                Text(String(yearB))
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
            }
        }
    }

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f
    }()

    private var monthSelectors: some View {
        HStack(spacing: 10) {
            periodPicker(label: "A") {
                DatePicker("", selection: $monthA, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(Theme.accent)
                    .colorScheme(.dark)
            } display: {
                Text(Self.monthFormatter.string(from: monthA).uppercased())
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(Theme.textPrimary)
            }
            periodPicker(label: "B") {
                DatePicker("", selection: $monthB, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(Theme.accent)
                    .colorScheme(.dark)
            } display: {
                Text(Self.monthFormatter.string(from: monthB).uppercased())
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(Theme.textPrimary)
            }
        }
    }

    private var customSelectors: some View {
        VStack(spacing: 10) {
            customRangePicker(label: "A", start: $customStartA, end: $customEndA)
            customRangePicker(label: "B", start: $customStartB, end: $customEndB)
        }
    }

    private func customRangePicker(label: String, start: Binding<Date>, end: Binding<Date>) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .heavy))
                .tracking(1)
                .foregroundColor(Theme.background)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Theme.accent))
            DatePicker("", selection: start, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(Theme.accent)
                .colorScheme(.dark)
            Text("to")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.textTertiary)
            DatePicker("", selection: end, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(Theme.accent)
                .colorScheme(.dark)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func periodPicker<P: View, D: View>(
        label: String,
        @ViewBuilder picker: () -> P,
        @ViewBuilder display: () -> D
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .heavy))
                .tracking(1)
                .foregroundColor(Theme.background)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Theme.accent))
            display()
            picker()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Results

    @ViewBuilder
    private var results: some View {
        let comparisons = buildComparisons()
        if comparisons == nil {
            selectPrompt
        } else if let comparisons, comparisons.metrics.isEmpty {
            noDataState
        } else if let comparisons {
            resultsCard(comparisons)
        }
    }

    private var selectPrompt: some View {
        VStack(spacing: 10) {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Theme.textTertiary)
            Text("SELECT BOTH SIDES TO COMPARE")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var noDataState: some View {
        VStack(spacing: 10) {
            Image(systemName: "xmark.circle")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Theme.textTertiary)
            Text("NO SHARED METRICS WITH DATA")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func resultsCard(_ data: ComparisonData) -> some View {
        VStack(spacing: 0) {
            resultsHeader(data)

            ForEach(Array(data.metrics.enumerated()), id: \.element.id) { index, metric in
                if index > 0 {
                    Divider().background(Theme.hairline)
                }
                metricRow(metric)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private func resultsHeader(_ data: ComparisonData) -> some View {
        HStack {
            Text(data.labelA)
                .font(.system(size: 11, weight: .heavy))
                .tracking(1)
                .foregroundColor(Theme.accent)
            Spacer()
            if let countA = data.countA, let countB = data.countB {
                Text("\(countA) vs \(countB) sessions")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
            }
            Spacer()
            Text(data.labelB)
                .font(.system(size: 11, weight: .heavy))
                .tracking(1)
                .foregroundColor(Theme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.surfaceElevated)
    }

    private func metricRow(_ metric: MetricComparison) -> some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                Text(metric.fieldName.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(Theme.textSecondary)

                if metric.fieldType == .number {
                    Button {
                        let current = higherIsBetter[metric.fieldName] ?? true
                        higherIsBetter[metric.fieldName] = !current
                    } label: {
                        Image(systemName: (higherIsBetter[metric.fieldName] ?? true) ? "arrow.up" : "arrow.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.textTertiary)
                            .frame(width: 18, height: 18)
                            .background(Theme.surfaceElevated)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }

            HStack {
                valueText(metric.displayValue(metric.valueA), isWinner: metric.winner == .a)
                    .frame(maxWidth: .infinity)
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(width: 1, height: 28)
                valueText(metric.displayValue(metric.valueB), isWinner: metric.winner == .b)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func valueText(_ text: String, isWinner: Bool) -> some View {
        Text(text)
            .font(.system(size: 20, weight: .heavy, design: .rounded))
            .foregroundColor(isWinner ? Theme.accent : Theme.textTertiary)
    }

    // MARK: - Build comparisons

    private struct ComparisonData {
        let labelA: String
        let labelB: String
        let countA: Int?
        let countB: Int?
        let metrics: [MetricComparison]
    }

    private func buildComparisons() -> ComparisonData? {
        switch mode {
        case .session:
            return buildSessionComparison()
        case .year:
            return buildYearComparison()
        case .month:
            return buildMonthComparison()
        case .custom:
            return buildCustomComparison()
        }
    }

    private func buildSessionComparison() -> ComparisonData? {
        guard let a = sessionA, let b = sessionB else { return nil }
        let metrics = ComparisonEngine.compareSessionValues(
            sessionA: a, sessionB: b,
            fields: plottableFields,
            higherIsBetterOverrides: higherIsBetter
        )
        return ComparisonData(
            labelA: a.trackName.isEmpty ? "SESSION A" : a.trackName.uppercased(),
            labelB: b.trackName.isEmpty ? "SESSION B" : b.trackName.uppercased(),
            countA: nil, countB: nil,
            metrics: metrics
        )
    }

    private func buildYearComparison() -> ComparisonData? {
        let cal = Calendar.current
        let a = filteredSessions.filter { cal.component(.year, from: $0.date) == yearA }
        let b = filteredSessions.filter { cal.component(.year, from: $0.date) == yearB }
        guard !a.isEmpty || !b.isEmpty else { return nil }
        let metrics = ComparisonEngine.comparePeriodAverages(
            sessionsA: a, sessionsB: b,
            fields: plottableFields,
            higherIsBetterOverrides: higherIsBetter
        )
        return ComparisonData(
            labelA: String(yearA), labelB: String(yearB),
            countA: a.count, countB: b.count,
            metrics: metrics
        )
    }

    private func buildMonthComparison() -> ComparisonData? {
        let cal = Calendar.current
        let a = filteredSessions.filter { cal.isDate($0.date, equalTo: monthA, toGranularity: .month) }
        let b = filteredSessions.filter { cal.isDate($0.date, equalTo: monthB, toGranularity: .month) }
        guard !a.isEmpty || !b.isEmpty else { return nil }
        let metrics = ComparisonEngine.comparePeriodAverages(
            sessionsA: a, sessionsB: b,
            fields: plottableFields,
            higherIsBetterOverrides: higherIsBetter
        )
        return ComparisonData(
            labelA: Self.monthFormatter.string(from: monthA).uppercased(),
            labelB: Self.monthFormatter.string(from: monthB).uppercased(),
            countA: a.count, countB: b.count,
            metrics: metrics
        )
    }

    private func buildCustomComparison() -> ComparisonData? {
        let a = filteredSessions.filter { $0.date >= customStartA && $0.date <= customEndA }
        let b = filteredSessions.filter { $0.date >= customStartB && $0.date <= customEndB }
        guard !a.isEmpty || !b.isEmpty else { return nil }
        let metrics = ComparisonEngine.comparePeriodAverages(
            sessionsA: a, sessionsB: b,
            fields: plottableFields,
            higherIsBetterOverrides: higherIsBetter
        )
        let fmt = Self.shortDateFormatter
        return ComparisonData(
            labelA: "\(fmt.string(from: customStartA)) – \(fmt.string(from: customEndA))".uppercased(),
            labelB: "\(fmt.string(from: customStartB)) – \(fmt.string(from: customEndB))".uppercased(),
            countA: a.count, countB: b.count,
            metrics: metrics
        )
    }
}

#Preview {
    SessionComparisonView()
        .modelContainer(for: [Session.self, CustomField.self, FieldValue.self], inMemory: true)
}
