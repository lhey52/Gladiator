//
//  RaceEngineerView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct RaceEngineerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\CustomField.sortOrder)])
    private var allFields: [CustomField]
    @Query(sort: [SortDescriptor(\Session.date, order: .reverse)])
    private var sessions: [Session]

    @State private var outcome: String = ""
    @State private var filter = AnalyticsFilterState()
    @State private var showingFilter: Bool = false
    @State private var showingOutcomePicker: Bool = false
    @State private var sliderPosition: Double = 0.5
    @State private var showingPaywall: Bool = false
    @State private var isInitialLoading: Bool = true
    @State private var showingDataSufficiencyDetail: Bool = false

    @State private var hasAnalyzed: Bool = false
    @State private var isAnalyzing: Bool = false
    @State private var analysisCache: AnalysisCache?
    @State private var panelCache: PanelCache?
    @State private var debounceTask: Task<Void, Never>?

    @ObservedObject private var iap = IAPManager.shared

    private var plottableFields: [CustomField] {
        allFields.filter { $0.fieldType.isPlottable }
    }

    private var canAnalyze: Bool {
        !outcome.isEmpty
    }

    private var outcomeFieldType: FieldType {
        plottableFields.first { $0.name == outcome }?.fieldType ?? .number
    }

    var body: some View {
        if isInitialLoading {
            AnalyticsLoadingView(
                toolName: "Race Engineer",
                sessionCount: sessions.count,
                onComplete: { isInitialLoading = false }
            )
        } else {
            toolContent
        }
    }

    private var toolContent: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                lockedContent
                if isAnalyzing {
                    analyzingOverlay
                }
            }
            .navigationTitle("Race Engineer")
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
            .sheet(isPresented: $showingOutcomePicker) {
                RaceEngineerOutcomePicker(
                    fields: plottableFields,
                    selected: outcome
                ) { name in
                    setOutcome(name)
                }
            }
            .sheet(isPresented: $showingDataSufficiencyDetail) {
                if let analysis = analysisCache {
                    RaceEngineerDataSufficiencyDetail(
                        level: DataSufficiencyLevel.from(sampleSize: analysis.sortedSnapshots.count),
                        sampleSize: analysis.sortedSnapshots.count,
                        outcome: outcome
                    )
                }
            }
            .fullScreenCover(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var lockedContent: some View {
        ZStack {
            mainContent
                .blur(radius: iap.isProUser ? 0 : 6)
                .allowsHitTesting(iap.isProUser)

            if !iap.isProUser {
                unlockOverlay
            }
        }
    }

    private var unlockOverlay: some View {
        Button { showingPaywall = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14, weight: .bold))
                Text("UNLOCK PRO")
                    .font(.system(size: 13, weight: .heavy))
                    .tracking(1.5)
            }
            .foregroundColor(Theme.accent)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Capsule().fill(Theme.surface))
            .overlay(Capsule().stroke(Theme.accent.opacity(0.5), lineWidth: 1))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Main

    @ViewBuilder
    private var mainContent: some View {
        if plottableFields.isEmpty {
            emptyState(
                icon: "chart.line.flattrend.xyaxis",
                headline: "ADD A METRIC",
                message: "Race Engineer needs at least one Number or Time metric. Add one in Settings to start comparing sessions."
            )
        } else {
            ScrollView {
                VStack(spacing: 18) {
                    ToolDescriptionCard(text: "Compare your setup across sessions to identify what changes between your best and worst results.")
                    outcomeCard
                    analyzeButton
                    if hasAnalyzed, let analysis = analysisCache {
                        if analysis.sortedSnapshots.count >= 4 {
                            comparisonSection(analysis: analysis)
                        } else {
                            notEnoughDataCard
                        }
                    }
                }
                .padding(20)
            }
        }
    }

    private func emptyState(icon: String, headline: String, message: String) -> some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.7))
            Text(headline)
                .font(.system(size: 14, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.textPrimary)
            Text(message)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Outcome card

    private var outcomeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select an outcome metric to compare:")
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(Theme.accent)

            Button { showingOutcomePicker = true } label: {
                HStack(spacing: 10) {
                    if let field = plottableFields.first(where: { $0.name == outcome }) {
                        Image(systemName: field.fieldType.systemImage)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.accent)
                        Text(outcome.uppercased())
                            .font(.system(size: 15, weight: .heavy))
                            .tracking(1)
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(1)
                    } else {
                        Text("SELECT FIELD")
                            .font(.system(size: 13, weight: .heavy))
                            .tracking(1)
                            .foregroundColor(Theme.textTertiary)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.textTertiary)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surfaceElevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.hairline, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
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

    // MARK: - Analyze button

    private var analyzeButton: some View {
        Button {
            runAnalysis()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.split.2x1.fill")
                    .font(.system(size: 13, weight: .heavy))
                Text("ANALYZE")
                    .font(.system(size: 14, weight: .heavy))
                    .tracking(1.5)
            }
            .foregroundColor(canAnalyze ? Theme.background : Theme.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(canAnalyze ? Theme.accent : Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(canAnalyze ? Theme.accent : Theme.hairline, lineWidth: 1)
            )
            .shadow(color: canAnalyze ? Theme.accent.opacity(0.4) : .clear, radius: 12)
        }
        .buttonStyle(.plain)
        .disabled(!canAnalyze)
    }

    private var analyzingOverlay: some View {
        ZStack {
            Theme.background.opacity(0.85).ignoresSafeArea()
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Theme.accent)
                    .scaleEffect(1.4)
                Text("RACE ENGINEER")
                    .font(.system(size: 13, weight: .heavy))
                    .tracking(2.5)
                    .foregroundColor(Theme.accent)
                Text("Comparing sessions by \(outcome)…")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Comparison section

    @ViewBuilder
    private func comparisonSection(analysis: AnalysisCache) -> some View {
        VStack(spacing: 14) {
            dataSufficiencyRow(analysis: analysis)
            sliderCard
            if let panel = panelCache {
                HStack(alignment: .top, spacing: 10) {
                    comparisonPanel(side: .lower, analysis: analysis, panel: panel)
                    comparisonPanel(side: .higher, analysis: analysis, panel: panel)
                }
            }
        }
    }

    // Sample size = sessions with the chosen outcome value present, after
    // the analytics filter is applied. Mirrors the way Correlation Analysis
    // counts samples for its own DataSufficiencyLevel computation.
    private func dataSufficiencyRow(analysis: AnalysisCache) -> some View {
        let level = DataSufficiencyLevel.from(sampleSize: analysis.sortedSnapshots.count)
        return Button {
            showingDataSufficiencyDetail = true
        } label: {
            HStack(spacing: 8) {
                Label("DATA SUFFICIENCY", systemImage: "square.stack.3d.up.fill")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.5)
                    .foregroundColor(Theme.accent)
                Spacer()
                DataSufficiencyBadge(level: level)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
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
        .buttonStyle(.plain)
    }

    // MARK: - Slider card

    private var sliderCard: some View {
        // Outcome name remains as the slider's title — the live percentage
        // and session-count labels now live in each panel's header instead.
        VStack(spacing: 14) {
            Text(outcome)
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            sliderControl
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

    // Uniform grey track with 9 evenly spaced tick marks (every 10%) and a
    // vertical pill thumb that protrudes past the top and bottom of the
    // track. Drag updates feed `sliderPosition`, which the existing
    // .onChange wires into the debounced panel refresh.
    private var sliderControl: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let trackHeight: CGFloat = 6
            let thumbWidth: CGFloat = 6
            let thumbHeight: CGFloat = 28
            let containerHeight: CGFloat = thumbHeight
            let thumbX = max(0, min(width, width * sliderPosition))

            ZStack {
                Capsule()
                    .fill(Theme.textTertiary)
                    .frame(width: width, height: trackHeight)

                ForEach(1..<10, id: \.self) { i in
                    let pct = CGFloat(i) / 10.0
                    Rectangle()
                        .fill(Theme.surface)
                        .frame(width: 1, height: trackHeight)
                        .position(x: width * pct, y: containerHeight / 2)
                }

                RoundedRectangle(cornerRadius: thumbWidth / 2, style: .continuous)
                    .fill(Theme.accent)
                    .frame(width: thumbWidth, height: thumbHeight)
                    .shadow(color: Theme.accent.opacity(0.5), radius: 6)
                    .position(x: thumbX, y: containerHeight / 2)
            }
            .frame(width: width, height: containerHeight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let new = max(0, min(1, value.location.x / width))
                        if new != sliderPosition {
                            sliderPosition = new
                        }
                    }
            )
        }
        .frame(height: 28)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Lower / higher split")
        .accessibilityValue("\(Int(round(sliderPosition * 100)))% lower, \(Int(round((1 - sliderPosition) * 100)))% higher")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                sliderPosition = min(1, sliderPosition + 0.05)
            case .decrement:
                sliderPosition = max(0, sliderPosition - 0.05)
            @unknown default:
                break
            }
        }
        .onChange(of: sliderPosition) { _, _ in
            scheduleDebouncedPanelRefresh()
        }
    }

    // MARK: - Panel

    private func comparisonPanel(
        side: PanelSide,
        analysis: AnalysisCache,
        panel: PanelCache
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            panelHeader(side: side, panel: panel)

            Divider().background(Theme.hairline)

            VStack(alignment: .leading, spacing: 6) {
                Text("SESSION AVERAGES")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.5)
                    .foregroundColor(Theme.textSecondary)
                outcomeRow(side: side, analysis: analysis, panel: panel)
            }

            if !panel.fieldOrder.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(panel.fieldOrder.enumerated()), id: \.element) { index, fieldName in
                        metricRow(
                            fieldName: fieldName,
                            side: side,
                            analysis: analysis,
                            panel: panel
                        )
                        if index < panel.fieldOrder.count - 1 {
                            Divider().background(Theme.hairline)
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    // Lowest/Highest tag + live percentage + live session count. The
    // percentage is driven directly off `sliderPosition` so it tracks the
    // thumb in real time even while the panel averages below are
    // debouncing. The count comes from `panel.splitIndex`, also live.
    private func panelHeader(side: PanelSide, panel: PanelCache) -> some View {
        let isLower = (side == .lower)
        let pct = isLower
            ? Int(round(sliderPosition * 100))
            : 100 - Int(round(sliderPosition * 100))
        let count = isLower
            ? panel.splitIndex
            : panel.totalSessions - panel.splitIndex

        return VStack(alignment: .leading, spacing: 4) {
            Text(isLower ? "LOWEST" : "HIGHEST")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(Theme.textSecondary)
            Text("\(pct)%")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            Text("\(count) session\(count == 1 ? "" : "s")")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
        }
    }

    private func outcomeRow(side: PanelSide, analysis: AnalysisCache, panel: PanelCache) -> some View {
        let avg = side == .lower ? panel.leftOutcomeAvg : panel.rightOutcomeAvg
        return VStack(alignment: .leading, spacing: 4) {
            Text(analysis.outcome.uppercased())
                .font(.system(size: 9, weight: .heavy))
                .tracking(1.2)
                .foregroundColor(Theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let avg {
                Text(formatValue(avg, fieldType: analysis.outcomeFieldType))
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            } else {
                Text("—")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.textTertiary)
            }
        }
    }

    private func metricRow(
        fieldName: String,
        side: PanelSide,
        analysis: AnalysisCache,
        panel: PanelCache
    ) -> some View {
        let avg = side == .lower ? panel.leftAverages[fieldName] : panel.rightAverages[fieldName]
        let fieldType = analysis.fieldTypes[fieldName] ?? .number
        let display = avg.map { formatValue($0, fieldType: fieldType) } ?? "—"
        let direction = direction(forFieldName: fieldName, side: side, panel: panel)

        return VStack(alignment: .leading, spacing: 3) {
            Text(fieldName.uppercased())
                .font(.system(size: 9, weight: .heavy))
                .tracking(1)
                .foregroundColor(Theme.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            HStack(spacing: 4) {
                Text(display)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(avg == nil ? Theme.textTertiary : Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                directionGlyph(direction)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    // .up if this panel's average is higher than the other panel's, .down
    // if lower, .none if the other side is missing a value or the two
    // averages are equal.
    private func direction(forFieldName name: String, side: PanelSide, panel: PanelCache) -> DirectionState {
        guard let left = panel.leftAverages[name],
              let right = panel.rightAverages[name] else {
            return .none
        }
        if abs(left - right) < 1e-9 { return .none }
        let thisSideHigher: Bool
        switch side {
        case .lower: thisSideHigher = left > right
        case .higher: thisSideHigher = right > left
        }
        return thisSideHigher ? .up : .down
    }

    @ViewBuilder
    private func directionGlyph(_ direction: DirectionState) -> some View {
        switch direction {
        case .up:
            Image(systemName: "arrow.up")
                .font(.system(size: 10, weight: .heavy))
                .foregroundColor(Theme.success)
        case .down:
            Image(systemName: "arrow.down")
                .font(.system(size: 10, weight: .heavy))
                .foregroundColor(Theme.danger)
        case .none:
            Image(systemName: "minus")
                .font(.system(size: 10, weight: .heavy))
                .foregroundColor(Theme.textTertiary)
        }
    }

    // MARK: - Empty state

    private var notEnoughDataCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.8))
            Text("NOT ENOUGH SESSIONS")
                .font(.system(size: 14, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.textPrimary)
            Text("Not enough sessions to compare. Log more sessions with \(outcome) recorded.")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Actions

    private func setOutcome(_ name: String) {
        debounceTask?.cancel()
        debounceTask = nil
        outcome = name
        hasAnalyzed = false
        analysisCache = nil
        panelCache = nil
    }

    private func runAnalysis() {
        guard canAnalyze else { return }
        debounceTask?.cancel()
        debounceTask = nil

        let outcomeName = outcome
        let outcomeType = outcomeFieldType
        let plottableSnapshot = plottableFields
        let plottableNames = Set(plottableSnapshot.map(\.name))
        let fieldNames = plottableSnapshot.filter { $0.name != outcomeName }.map(\.name)
        let fieldTypes: [String: FieldType] = Dictionary(
            uniqueKeysWithValues: plottableSnapshot.map { ($0.name, $0.fieldType) }
        )
        let criteria = FilterCriteria(
            selectedTracks: filter.selectedTracks,
            selectedVehicles: filter.selectedVehicles,
            startDate: filter.startDate,
            endDate: filter.endDate
        )

        // SwiftData @Model accessors aren't safe off the main actor, so the
        // raw extraction has to happen here. Everything downstream operates
        // on the resulting Sendable snapshots and runs on a background
        // executor.
        let snapshots: [SessionSnapshot] = sessions.map { session in
            var values: [String: Double] = [:]
            for fv in session.fieldValues where plottableNames.contains(fv.fieldName) {
                let raw = fv.value.trimmingCharacters(in: .whitespaces)
                guard !raw.isEmpty, let val = Double(raw) else { continue }
                if fv.fieldType == .time, val == 0 { continue }
                values[fv.fieldName] = val
            }
            return SessionSnapshot(
                trackName: session.trackName,
                vehicleName: session.vehicleName,
                date: session.date,
                numericValues: values
            )
        }

        analysisCache = nil
        panelCache = nil
        hasAnalyzed = false
        sliderPosition = 0.5
        withAnimation(.easeInOut(duration: 0.2)) { isAnalyzing = true }

        Task.detached(priority: .userInitiated) {
            let cache = AnalysisCache.compute(
                snapshots: snapshots,
                filter: criteria,
                outcome: outcomeName,
                outcomeFieldType: outcomeType,
                fieldNames: fieldNames,
                fieldTypes: fieldTypes
            )
            let panel = PanelCache.compute(from: cache, sliderPosition: 0.5)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.25)) {
                    analysisCache = cache
                    panelCache = panel
                    hasAnalyzed = true
                    isAnalyzing = false
                }
            }
        }
    }

    // Slider drag fires `onChange` continuously; debounce so we don't
    // recompute the panels on every frame. Counts and thumb position
    // remain reactive — only the heavier panel content waits.
    private func scheduleDebouncedPanelRefresh() {
        guard let cache = analysisCache else { return }
        debounceTask?.cancel()
        let position = sliderPosition
        debounceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            if Task.isCancelled { return }
            let panel = await Task.detached(priority: .userInitiated) {
                PanelCache.compute(from: cache, sliderPosition: position)
            }.value
            if Task.isCancelled { return }
            panelCache = panel
        }
    }

    // MARK: - Formatting

    private func formatValue(_ value: Double, fieldType: FieldType) -> String {
        switch fieldType {
        case .time:
            return TimeFormatting.secondsToDisplay(value)
        case .number, .text:
            let magnitude = abs(value)
            if magnitude >= 100 {
                return String(format: "%.1f", value)
            } else if magnitude >= 10 {
                return String(format: "%.2f", value)
            } else {
                return String(format: "%.3f", value)
            }
        }
    }
}

// MARK: - Snapshots and caches

private enum PanelSide {
    case lower, higher
}

private enum DirectionState {
    case up, down, none
}

private struct SessionSnapshot: Sendable {
    let trackName: String
    let vehicleName: String
    let date: Date
    // Pre-parsed numeric values keyed by field name. Time fields with a raw
    // value of 0 are dropped here so downstream code never has to special-
    // case them.
    let numericValues: [String: Double]
}

private struct FilterCriteria: Sendable {
    let selectedTracks: Set<String>
    let selectedVehicles: Set<String>
    let startDate: Date?
    let endDate: Date?

    func matches(_ snap: SessionSnapshot) -> Bool {
        if !selectedTracks.isEmpty, !selectedTracks.contains(snap.trackName) { return false }
        if !selectedVehicles.isEmpty, !selectedVehicles.contains(snap.vehicleName) { return false }
        if let start = startDate, snap.date < start { return false }
        if let end = endDate {
            let extended = Calendar.current.date(byAdding: .day, value: 1, to: end) ?? end
            if snap.date > extended { return false }
        }
        return true
    }
}

private struct FieldRange: Sendable {
    let min: Double
    let max: Double
}

// Computed once per Analyze tap. Captures every input the panels need so
// slider drags only have to recompute averages on a fixed dataset, not
// re-filter or re-sort.
private struct AnalysisCache: Sendable {
    let outcome: String
    let outcomeFieldType: FieldType
    let fieldNames: [String]
    let fieldTypes: [String: FieldType]
    let sortedSnapshots: [SessionSnapshot]
    let fieldRanges: [String: FieldRange]

    static func compute(
        snapshots: [SessionSnapshot],
        filter: FilterCriteria,
        outcome: String,
        outcomeFieldType: FieldType,
        fieldNames: [String],
        fieldTypes: [String: FieldType]
    ) -> AnalysisCache {
        let filtered = snapshots.filter { snap in
            filter.matches(snap) && snap.numericValues[outcome] != nil
        }
        let sorted = filtered.sorted {
            ($0.numericValues[outcome] ?? 0) < ($1.numericValues[outcome] ?? 0)
        }
        var ranges: [String: FieldRange] = [:]
        for name in fieldNames {
            let values = sorted.compactMap { $0.numericValues[name] }
            guard let mn = values.min(), let mx = values.max() else { continue }
            ranges[name] = FieldRange(min: mn, max: mx)
        }
        return AnalysisCache(
            outcome: outcome,
            outcomeFieldType: outcomeFieldType,
            fieldNames: fieldNames,
            fieldTypes: fieldTypes,
            sortedSnapshots: sorted,
            fieldRanges: ranges
        )
    }
}

// Recomputed on each debounced slider settle. Cheap relative to
// AnalysisCache because the heavy filter / sort / range work is already
// baked into the analysis input.
private struct PanelCache: Sendable {
    let totalSessions: Int
    let splitIndex: Int
    let leftOutcomeAvg: Double?
    let rightOutcomeAvg: Double?
    let fieldOrder: [String]
    let leftAverages: [String: Double]
    let rightAverages: [String: Double]

    static func compute(from analysis: AnalysisCache, sliderPosition: Double) -> PanelCache {
        let total = analysis.sortedSnapshots.count
        let split = min(max(0, Int(round(sliderPosition * Double(total)))), total)
        let leftSlice = Array(analysis.sortedSnapshots.prefix(split))
        let rightSlice = Array(analysis.sortedSnapshots.suffix(total - split))

        func avg(_ slice: [SessionSnapshot], for name: String) -> Double? {
            let vals = slice.compactMap { $0.numericValues[name] }
            guard !vals.isEmpty else { return nil }
            return vals.reduce(0, +) / Double(vals.count)
        }

        let leftOutcome = avg(leftSlice, for: analysis.outcome)
        let rightOutcome = avg(rightSlice, for: analysis.outcome)

        var leftAverages: [String: Double] = [:]
        var rightAverages: [String: Double] = [:]
        for name in analysis.fieldNames {
            if let l = avg(leftSlice, for: name) { leftAverages[name] = l }
            if let r = avg(rightSlice, for: name) { rightAverages[name] = r }
        }

        // Normalize each metric's between-panel delta by its own observed
        // range so PSI / seconds / degrees compete fairly for the
        // descending sort order.
        var diffs: [(name: String, diff: Double)] = []
        for name in analysis.fieldNames {
            guard let l = leftAverages[name], let r = rightAverages[name] else { continue }
            let raw = abs(r - l)
            let normalized: Double
            if let range = analysis.fieldRanges[name], range.max > range.min {
                normalized = raw / (range.max - range.min)
            } else {
                normalized = raw
            }
            diffs.append((name: name, diff: normalized))
        }
        diffs.sort { $0.diff > $1.diff }

        let withDiffSet = Set(diffs.map { $0.name })
        var order = diffs.map { $0.name }
        for name in analysis.fieldNames where !withDiffSet.contains(name) {
            order.append(name)
        }

        return PanelCache(
            totalSessions: total,
            splitIndex: split,
            leftOutcomeAvg: leftOutcome,
            rightOutcomeAvg: rightOutcome,
            fieldOrder: order,
            leftAverages: leftAverages,
            rightAverages: rightAverages
        )
    }
}

// MARK: - Data sufficiency detail sheet

// Mirrors the modal style used by CorrelationPairDetailView in the
// Correlation Matrix — NavigationStack + Theme.background + xmark close
// button + a single result card. Reuses `DataSufficiencyLevel.description`
// so the body text already explains the level and how many sessions are
// needed to reach the next tier.
private struct RaceEngineerDataSufficiencyDetail: View {
    @Environment(\.dismiss) private var dismiss
    let level: DataSufficiencyLevel
    let sampleSize: Int
    let outcome: String

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        outcomeHeader
                        detailCard
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Data Sufficiency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var outcomeHeader: some View {
        HStack {
            Text(outcome.uppercased())
                .font(.system(size: 13, weight: .heavy))
                .tracking(1)
                .foregroundColor(Theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.accent.opacity(0.35), lineWidth: 1)
        )
    }

    private var detailCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("DATA SUFFICIENCY", systemImage: "square.stack.3d.up.fill")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Theme.accent)

            DataSufficiencyBadge(level: level)

            Text(level.description(sampleSize: sampleSize))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
                Text("\(sampleSize) session\(sampleSize == 1 ? "" : "s") analyzed")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.8)
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
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }
}

// MARK: - Outcome picker sheet

private struct RaceEngineerOutcomePicker: View {
    @Environment(\.dismiss) private var dismiss
    let fields: [CustomField]
    let selected: String?
    let onSelect: (String) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                content
            }
            .navigationTitle("Select Metric")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var content: some View {
        if fields.isEmpty {
            VStack(spacing: 10) {
                Spacer()
                Image(systemName: "slash.circle")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
                Text("NO FIELDS AVAILABLE")
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(1.5)
                    .foregroundColor(Theme.textTertiary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(fields) { field in
                        Button {
                            onSelect(field.name)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: field.fieldType.systemImage)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(Theme.accent)
                                Text(field.name)
                                    .font(.system(size: 15, weight: .heavy))
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                if field.name == selected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(Theme.accent)
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(field.name == selected ? Theme.accent.opacity(0.1) : Theme.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(field.name == selected ? Theme.accent.opacity(0.5) : Theme.hairline, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
        }
    }
}

#Preview {
    RaceEngineerView()
        .modelContainer(for: [Session.self, CustomField.self, FieldValue.self, Track.self, Vehicle.self], inMemory: true)
}
