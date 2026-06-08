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

    @State private var hasAnalyzed: Bool = false
    @State private var isAnalyzing: Bool = false
    @State private var analysisCache: AnalysisCache?
    @State private var panelCache: PanelCache?
    @State private var debounceTask: Task<Void, Never>?

    @ObservedObject private var iap = IAPManager.shared

    private var plottableFields: [CustomField] {
        // Time metrics float to the top of the outcome picker — the
        // typical Race Engineer comparison is "what changed when lap
        // time moved", so surfacing those first saves a scroll. Falls
        // back to CustomField.sortOrder within each group.
        allFields
            .filter { $0.fieldType.isPlottable }
            .sorted { a, b in
                if (a.fieldType == .time) != (b.fieldType == .time) {
                    return a.fieldType == .time
                }
                return a.sortOrder < b.sortOrder
            }
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
            .fullScreenCover(isPresented: $showingPaywall) {
                PaywallView()
            }
            .onChange(of: showingFilter) { _, isShowing in
                // Filter sheet just dismissed — re-run analysis if we
                // had previous results so the readout stays in sync
                // without an explicit Reanalyze tap.
                if !isShowing, hasAnalyzed, !outcome.isEmpty {
                    runAnalysis()
                }
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
                VStack(spacing: 14) {
                    diagnosticHeader
                    if outcome.isEmpty {
                        outcomePromptCard
                    } else if hasAnalyzed, let analysis = analysisCache {
                        if analysis.sortedSnapshots.count >= 4 {
                            thresholdCursorPanel(analysis: analysis)
                            if let panel = panelCache {
                                comparisonReadoutPanel(analysis: analysis, panel: panel)
                            }
                        } else {
                            notEnoughDataCard
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 28)
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

    // MARK: - Diagnostic header

    // Compact instrument strip — outcome selector spans the full section
    // width, with dataset status centered underneath. Reads as a diagnostic
    // console header rather than a labeled form.
    private var diagnosticHeader: some View {
        VStack(spacing: 10) {
            outcomePill
            datasetReadout
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .bracketPanel(.hero)
    }

    private var outcomePill: some View {
        Button { showingOutcomePicker = true } label: {
            HStack(spacing: 10) {
                Text("OUTCOME")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .tracking(1.4)
                    .foregroundColor(Theme.accent)
                Rectangle()
                    .fill(Theme.accent.opacity(0.4))
                    .frame(width: 1, height: 14)
                Spacer(minLength: 0)
                if let field = plottableFields.first(where: { $0.name == outcome }) {
                    HStack(spacing: 6) {
                        Image(systemName: field.fieldType.systemImage)
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(Theme.textPrimary)
                        Text(outcome.uppercased())
                            .font(.system(size: 14, weight: .heavy))
                            .tracking(0.8)
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                } else {
                    Text("TAP TO SELECT")
                        .font(.system(size: 13, weight: .heavy))
                        .tracking(0.8)
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(Theme.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Theme.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(outcome.isEmpty ? Theme.accent.opacity(0.5) : Theme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var datasetReadout: some View {
        let count = plottableFields.isEmpty ? 0 : (analysisCache?.sortedSnapshots.count ?? sessions.count)
        return HStack(spacing: 8) {
            Text("n = \(count)")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .monospacedDigit()
                .foregroundColor(Theme.textPrimary)
            Text("·")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundColor(Theme.textTertiary)
            Text(filter.isActive ? "FILTERED" : "ALL SESSIONS")
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .tracking(1.4)
                .foregroundColor(filter.isActive ? Theme.accent : Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Pick prompt placeholder

    private var outcomePromptCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "scope")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(Theme.accent.opacity(0.7))
            Text("AWAITING OUTCOME")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .tracking(2)
                .foregroundColor(Theme.textSecondary)
            Text("Pick the metric you want to diagnose — the tool will sort sessions by it and split them into a lower and higher group for side-by-side comparison.")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Analyzing overlay

    private var analyzingOverlay: some View {
        ZStack {
            Theme.background.opacity(0.88).ignoresSafeArea()
            VStack(spacing: 18) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Theme.accent)
                    .scaleEffect(1.3)
                Text("RACE ENGINEER")
                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                    .tracking(2.5)
                    .foregroundColor(Theme.accent)
                Text("Comparing sessions by \(outcome)…")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Threshold cursor panel

    // Top hero panel. Wraps the slider in a bracket-cornered frame with the
    // sufficiency badge + reliability blurb above, and a short footnote on
    // the colored track underneath. Concrete per-side counts live in the
    // comparison header below, where the slider's effect is most visible.
    private func thresholdCursorPanel(analysis: AnalysisCache) -> some View {
        let total = analysis.sortedSnapshots.count
        let sufficiency = DataSufficiencyLevel.from(smallerBucketSize: smallerBucketSize(for: analysis))

        // Live split shares — derived from the immediate slider position so
        // the end labels lead the debounced comparison header during a drag.
        let lowerCountLive = liveSplitIndex(for: analysis)
        let lowerPctLive = total > 0 ? Int(round(Double(lowerCountLive) / Double(total) * 100)) : 50
        let higherPctLive = 100 - lowerPctLive

        return VStack(spacing: 14) {
            // Top label row
            HStack {
                Label("ADJUST SPLIT", systemImage: "square.split.2x1")
                    .labelStyle(.titleAndIcon)
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .tracking(1.4)
                    .foregroundColor(Theme.accent)
                Spacer()
                DataSufficiencyBadge(level: sufficiency)
            }

            // Reliability blurb — tracks the sufficiency tier so the user
            // knows how much to trust the comparison before they touch the
            // slider. Always reserves two lines of vertical space so the
            // panel doesn't jump when the user drags the slider between
            // tiers with short and long descriptions.
            Text(sufficiencyDescription(for: sufficiency))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .lineLimit(2, reservesSpace: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            // End labels framing the track. Each side carries its live share
            // of the split so the LOWER/HIGHER ends visibly own a percentage,
            // updating instantly as the thumb is dragged.
            HStack {
                HStack(spacing: 5) {
                    Text("LOWEST")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .tracking(1.4)
                        .foregroundColor(Theme.textSecondary)
                    Text("\(lowerPctLive)%")
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .monospacedDigit()
                        .foregroundColor(Theme.accent)
                        .contentTransition(.numericText())
                        .splitSharePulse()
                }
                Spacer()
                HStack(spacing: 5) {
                    Text("\(higherPctLive)%")
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .monospacedDigit()
                        .foregroundColor(Theme.accent)
                        .contentTransition(.numericText())
                        .splitSharePulse()
                    Text("HIGHEST")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .tracking(1.4)
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: lowerPctLive)

            sliderControl(totalSessions: total)

            // Percentile scale — 5 evenly-spaced labels so each one's center
            // lands at 10/30/50/70/90% of the slider's track width.
            HStack(spacing: 0) {
                ForEach(["P10", "P30", "P50", "P70", "P90"], id: \.self) { mark in
                    Text(mark)
                        .font(.system(size: 8, weight: .heavy, design: .monospaced))
                        .tracking(0.6)
                        .foregroundColor(Theme.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Footnote — explains the colored track without spelling out the
            // sufficiency tier math. Intentionally generic so it stays
            // accurate at any session count.
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
                Text("Color bands shift as more sessions are added.")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Theme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .bracketPanel(.hero)
    }

    private func sufficiencyDescription(for level: DataSufficiencyLevel) -> String {
        switch level {
        case .bad: return "Too few sessions for a reliable comparison."
        case .poor: return "Limited data — treat results as early indicators only."
        case .fair: return "Comparison is directionally useful but expect some movement as more data accumulates."
        case .good: return "Solid foundation — results are reasonably reliable."
        case .excellent: return "Strong data foundation — high confidence in results."
        }
    }

    // Track is split into colored segments matching each sufficiency tier
    // based on the smaller of the two buckets at every slider position.
    // Segments are mirrored on both ends because either side can be the
    // smaller bucket — moving the thumb toward an edge shrinks that side.
    // Nine evenly spaced tick marks and a vertical pill thumb sit on top.
    private func sliderControl(totalSessions: Int) -> some View {
        GeometryReader { geo in
            let width = geo.size.width
            let trackHeight: CGFloat = 6
            let thumbWidth: CGFloat = 6
            let thumbHeight: CGFloat = 32
            let hintHeight: CGFloat = 16
            let trackCenterY: CGFloat = thumbHeight / 2
            let containerHeight: CGFloat = thumbHeight + hintHeight
            let thumbX = max(0, min(width, width * sliderPosition))

            ZStack {
                sliderTrack(width: width, height: trackHeight, totalSessions: totalSessions)
                    .frame(width: width, height: trackHeight)
                    .position(x: width / 2, y: trackCenterY)

                ForEach(1..<10, id: \.self) { i in
                    let pct = CGFloat(i) / 10.0
                    Rectangle()
                        .fill(Theme.surface)
                        .frame(width: 1, height: trackHeight)
                        .position(x: width * pct, y: trackCenterY)
                }

                RoundedRectangle(cornerRadius: thumbWidth / 2, style: .continuous)
                    .fill(Theme.accent)
                    .frame(width: thumbWidth, height: thumbHeight)
                    .shadow(color: Theme.accent.opacity(0.55), radius: 6)
                    .position(x: thumbX, y: trackCenterY)

                // Drag affordance — a small caret beneath the thumb that
                // pulses intermittently so first-time users register the
                // track as a draggable control. Tracks the thumb horizontally.
                dragHintTriangle
                    .position(x: thumbX, y: thumbHeight + hintHeight / 2)
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
        .frame(height: 48)
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

    // Pulsing left/right carets that hint the slider is draggable. The
    // opposed triangles indicate the horizontal drag action. Cycles idle →
    // pulse → hold, with a long dwell on idle so the pulse reads as
    // intermittent rather than a constant throb.
    private var dragHintTriangle: some View {
        HStack(spacing: 5) {
            Image(systemName: "arrowtriangle.left.fill")
            Image(systemName: "arrowtriangle.right.fill")
        }
        .font(.system(size: 10, weight: .bold))
        .foregroundColor(Theme.accent)
        .phaseAnimator(SliderHintPhase.allCases) { content, phase in
            content
                .scaleEffect(phase.scale)
                .opacity(phase.opacity)
        } animation: { phase in
            phase.animation
        }
    }

    private func sliderTrack(width: CGFloat, height: CGFloat, totalSessions: Int) -> some View {
        let segments = sufficiencySegments(totalSessions: totalSessions)
        return HStack(spacing: 0) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, seg in
                Rectangle()
                    .fill(seg.color)
                    .frame(width: max(0, width * CGFloat(seg.end - seg.start)))
            }
        }
        .frame(width: width, height: height)
        .clipShape(Capsule())
    }

    // Builds the color segments shown along the slider track. Boundaries
    // match the points where the smaller bucket crosses each sufficiency
    // threshold (6 / 11 / 16 / 25). Subtracting 0.5 before dividing by the
    // total accounts for the `round(p * T)` rounding the badge uses to
    // pick a tier, so a slider position lands on the same color as the
    // badge it would produce. When the total session count is too small
    // for a tier to be reachable, that color is simply omitted.
    private func sufficiencySegments(totalSessions T: Int) -> [SliderTrackSegment] {
        let levelColors: [Color] = [
            DataSufficiencyLevel.bad.color,
            DataSufficiencyLevel.poor.color,
            DataSufficiencyLevel.fair.color,
            DataSufficiencyLevel.good.color,
            DataSufficiencyLevel.excellent.color
        ]

        guard T > 0 else {
            return [SliderTrackSegment(start: 0, end: 1, color: levelColors[0])]
        }

        let total = Double(T)
        let thresholds: [Double] = [6, 11, 16, 25].map { (Double($0) - 0.5) / total }
        var leftBoundaries: [Double] = []
        for t in thresholds {
            if t < 0.5 { leftBoundaries.append(t) } else { break }
        }

        var segments: [SliderTrackSegment] = []
        var cursor: Double = 0

        for (i, b) in leftBoundaries.enumerated() {
            segments.append(SliderTrackSegment(start: cursor, end: b, color: levelColors[i]))
            cursor = b
        }

        if let lastBoundary = leftBoundaries.last {
            let highestReachable = leftBoundaries.count
            let midEnd = 1 - lastBoundary
            segments.append(SliderTrackSegment(start: cursor, end: midEnd, color: levelColors[highestReachable]))
            cursor = midEnd

            for i in stride(from: leftBoundaries.count - 1, through: 0, by: -1) {
                let segEnd: Double = (i == 0) ? 1.0 : (1 - leftBoundaries[i - 1])
                segments.append(SliderTrackSegment(start: cursor, end: segEnd, color: levelColors[i]))
                cursor = segEnd
            }
        } else {
            segments.append(SliderTrackSegment(start: 0, end: 1, color: levelColors[0]))
        }

        return segments
    }

    // MARK: - Comparison readout

    // Spec-sheet style table. Header strip names the two sides, outcome row
    // pinned at top with bracket emphasis, contributor rows ordered by
    // normalized delta. Each row shows a thin delta bar indicating direction
    // and magnitude, plus the signed numeric Δ.
    private func comparisonReadoutPanel(analysis: AnalysisCache, panel: PanelCache) -> some View {
        VStack(spacing: 0) {
            comparisonHeaderStrip(panel: panel)
            outcomeRow(analysis: analysis, panel: panel)
            ForEach(Array(panel.fieldOrder.enumerated()), id: \.element) { index, fieldName in
                Rectangle()
                    .fill(Theme.hairline)
                    .frame(height: 1)
                metricRow(
                    rank: index,
                    fieldName: fieldName,
                    analysis: analysis,
                    panel: panel
                )
            }
        }
        .bracketPanel(.hero)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    // Comparison header — the place where the slider's effect on the split
    // is most visible. Each side gets a two-line block showing percent of
    // sessions and the actual count. Δ glyph sits centered between the two.
    private func comparisonHeaderStrip(panel: PanelCache) -> some View {
        let lowerCount = panel.splitIndex
        let higherCount = panel.totalSessions - panel.splitIndex
        let total = max(1, panel.totalSessions)
        let lowerPct = Int(round(Double(lowerCount) / Double(total) * 100))
        let higherPct = 100 - lowerPct

        return HStack(alignment: .center, spacing: 10) {
            comparisonHeaderSide(label: "LOWEST", percent: lowerPct, count: lowerCount, alignment: .leading)
            Text("Δ")
                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                .foregroundColor(Theme.accent)
            comparisonHeaderSide(label: "HIGHEST", percent: higherPct, count: higherCount, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Theme.surfaceElevated)
    }

    private func comparisonHeaderSide(label: String, percent: Int, count: Int, alignment: HorizontalAlignment) -> some View {
        let frameAlignment: Alignment = alignment == .leading ? .leading : .trailing
        let sessionWord = "\(count) session\(count == 1 ? "" : "s")"

        return VStack(alignment: alignment, spacing: 3) {
            HStack(spacing: 6) {
                if alignment == .trailing {
                    Spacer(minLength: 0)
                    Text("\(percent)%")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(Theme.textPrimary)
                    Text(label)
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .tracking(1.4)
                        .foregroundColor(Theme.accent)
                } else {
                    Text(label)
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .tracking(1.4)
                        .foregroundColor(Theme.accent)
                    Text("\(percent)%")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(Theme.textPrimary)
                    Spacer(minLength: 0)
                }
            }
            // Spell out what the percentile is OF — the selected outcome
            // metric — on its own line, in a lighter, non-monospaced style so
            // it reads as a caption under the bold "LOWEST 42%".
            (
                Text("of ").foregroundColor(Theme.textTertiary)
                    + Text(outcome).foregroundColor(Theme.textSecondary)
            )
            .font(.system(size: 11, weight: .semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity, alignment: frameAlignment)

            Text(sessionWord.uppercased())
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .tracking(1)
                .monospacedDigit()
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: frameAlignment)
    }

    private func outcomeRow(analysis: AnalysisCache, panel: PanelCache) -> some View {
        let leftAvg = panel.leftOutcomeAvg
        let rightAvg = panel.rightOutcomeAvg
        let leftDisplay = leftAvg.map { formatValue($0, fieldType: analysis.outcomeFieldType) } ?? "—"
        let rightDisplay = rightAvg.map { formatValue($0, fieldType: analysis.outcomeFieldType) } ?? "—"
        let signed = signedDelta(leftAvg, rightAvg)
        let normalized = 1.0 // outcome bar always at full magnitude — it IS the axis
        let rightHigher = (rightAvg ?? 0) > (leftAvg ?? 0)

        return VStack(spacing: 10) {
            Text(analysis.outcome.uppercased())
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .tracking(1.4)
                .foregroundColor(Theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .center)
            HStack(alignment: .center, spacing: 12) {
                Text(leftDisplay)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(leftAvg == nil ? Theme.textTertiary : Theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                DeltaIndicator(
                    normalized: normalized,
                    rightHigher: rightHigher,
                    deltaText: signed.flatMap { formatSignedDelta($0, fieldType: analysis.outcomeFieldType) } ?? "—",
                    isOutcome: true
                )
                .frame(maxWidth: .infinity)
                Text(rightDisplay)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(rightAvg == nil ? Theme.textTertiary : Theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Theme.accent.opacity(0.05))
    }

    private func metricRow(rank: Int, fieldName: String, analysis: AnalysisCache, panel: PanelCache) -> some View {
        let leftAvg = panel.leftAverages[fieldName]
        let rightAvg = panel.rightAverages[fieldName]
        let fieldType = analysis.fieldTypes[fieldName] ?? .number
        let leftDisplay = leftAvg.map { formatValue($0, fieldType: fieldType) } ?? "—"
        let rightDisplay = rightAvg.map { formatValue($0, fieldType: fieldType) } ?? "—"
        let signed = signedDelta(leftAvg, rightAvg)
        let normalized = panel.normalizedDeltas[fieldName] ?? 0
        let rightHigher = (rightAvg ?? 0) > (leftAvg ?? 0)
        let rankOpacity: Double = {
            switch rank {
            case 0: return 0.9
            case 1: return 0.55
            case 2: return 0.3
            default: return 0
            }
        }()

        return HStack(spacing: 0) {
            // Rank stripe — fades through top 3 contributors, vanishes for the rest
            Rectangle()
                .fill(Theme.accent.opacity(rankOpacity))
                .frame(width: 2)
            VStack(spacing: 8) {
                Text(fieldName.uppercased())
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .tracking(1.2)
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity, alignment: .center)
                HStack(alignment: .center, spacing: 12) {
                    Text(leftDisplay)
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(leftAvg == nil ? Theme.textTertiary : Theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    DeltaIndicator(
                        normalized: normalized,
                        rightHigher: rightHigher,
                        deltaText: signed.flatMap { formatSignedDelta($0, fieldType: fieldType) } ?? "—",
                        isOutcome: false
                    )
                    .frame(maxWidth: .infinity)
                    Text(rightDisplay)
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(rightAvg == nil ? Theme.textTertiary : Theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Empty state

    private var notEnoughDataCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.8))
            Text("NOT ENOUGH SESSIONS")
                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                .tracking(2)
                .foregroundColor(Theme.textPrimary)
            Text("Not enough sessions to compare. Log more sessions with \(outcome) recorded.")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
        )
        .overlay(BracketCorners(color: Theme.accent.opacity(0.55), size: 10, lineWidth: 1.2))
    }

    // MARK: - Actions

    private func setOutcome(_ name: String) {
        debounceTask?.cancel()
        debounceTask = nil
        outcome = name
        hasAnalyzed = false
        analysisCache = nil
        panelCache = nil
        runAnalysis()
    }

    private func runAnalysis() {
        guard !outcome.isEmpty else { return }
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
        let snapshots: [RaceEngineerSnapshot] = sessions.map { session in
            var values: [String: Double] = [:]
            for fv in session.fieldValues where plottableNames.contains(fv.fieldName) {
                let raw = fv.value.trimmingCharacters(in: .whitespaces)
                guard !raw.isEmpty, let val = Double(raw) else { continue }
                if fv.fieldType == .time, val == 0 { continue }
                values[fv.fieldName] = val
            }
            return RaceEngineerSnapshot(
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

    // Live count of sessions on the lower-outcome side of the slider at the
    // current sliderPosition. Read directly off the state value so labels,
    // sufficiency badge, and detail sheet all update without waiting on the
    // panel debounce.
    private func liveSplitIndex(for analysis: AnalysisCache) -> Int {
        let total = analysis.sortedSnapshots.count
        return min(max(0, Int(round(sliderPosition * Double(total)))), total)
    }

    // Smaller of the two buckets — the binding constraint on comparison
    // reliability, since either side's average is only as trustworthy as
    // its own sample size.
    private func smallerBucketSize(for analysis: AnalysisCache) -> Int {
        let split = liveSplitIndex(for: analysis)
        return min(split, analysis.sortedSnapshots.count - split)
    }

    // MARK: - Formatting

    private func signedDelta(_ left: Double?, _ right: Double?) -> Double? {
        guard let l = left, let r = right else { return nil }
        return r - l
    }

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

    private func formatSignedDelta(_ value: Double, fieldType: FieldType) -> String {
        let sign = value > 0 ? "+" : (value < 0 ? "−" : "")
        let magnitude = abs(value)
        switch fieldType {
        case .time:
            // Time deltas are reported in seconds — full mm:ss formatting
            // would make a 0.08s delta unreadable.
            if magnitude >= 1 {
                return "Δ \(sign)\(String(format: "%.2f", magnitude))s"
            } else {
                return "Δ \(sign)\(String(format: "%.3f", magnitude))s"
            }
        case .number, .text:
            if magnitude >= 100 {
                return "Δ \(sign)\(String(format: "%.1f", magnitude))"
            } else if magnitude >= 10 {
                return "Δ \(sign)\(String(format: "%.2f", magnitude))"
            } else {
                return "Δ \(sign)\(String(format: "%.3f", magnitude))"
            }
        }
    }
}

// MARK: - Bracket frame

// Four L-shaped corner marks drawn over a container. Signature engineering
// motif — gives a panel "instrument panel" framing without adding a heavy
// border. Sized in points; corners scale with the parent. Kept internal so
// other views (Analytics tile list, etc.) can reuse the same treatment.
struct BracketCorners: View {
    var color: Color = Theme.accent.opacity(0.55)
    var size: CGFloat = 12
    var lineWidth: CGFloat = 1.4

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            Path { path in
                // Top-left
                path.move(to: CGPoint(x: 0, y: size))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: size, y: 0))
                // Top-right
                path.move(to: CGPoint(x: w - size, y: 0))
                path.addLine(to: CGPoint(x: w, y: 0))
                path.addLine(to: CGPoint(x: w, y: size))
                // Bottom-right
                path.move(to: CGPoint(x: w, y: h - size))
                path.addLine(to: CGPoint(x: w, y: h))
                path.addLine(to: CGPoint(x: w - size, y: h))
                // Bottom-left
                path.move(to: CGPoint(x: size, y: h))
                path.addLine(to: CGPoint(x: 0, y: h))
                path.addLine(to: CGPoint(x: 0, y: h - size))
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .square, lineJoin: .miter))
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Delta indicator

// Thin horizontal track with a fill bar extending from center toward the
// higher-value side, magnitude proportional to the normalized delta. The
// signed Δ value sits below. Two visual styles: outcome (accent-colored,
// larger) and contributor (subdued white).
private struct DeltaIndicator: View {
    let normalized: Double
    let rightHigher: Bool
    let deltaText: String
    let isOutcome: Bool

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let w = geo.size.width
                let half = w / 2
                let magnitude = max(0, min(1, normalized))
                let fillWidth = half * magnitude

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.hairline)
                        .frame(width: w, height: 3)

                    Capsule()
                        .fill(isOutcome ? Theme.accent : Color.white.opacity(0.55))
                        .frame(width: fillWidth, height: 3)
                        .offset(x: rightHigher ? half : (half - fillWidth))

                    Rectangle()
                        .fill(Theme.textTertiary)
                        .frame(width: 1, height: 8)
                        .offset(x: half - 0.5, y: -2.5)
                }
                .frame(height: 8, alignment: .center)
            }
            .frame(height: 8)

            Text(deltaText)
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .tracking(0.4)
                .foregroundColor(isOutcome ? Theme.accent : Theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

// MARK: - Slider hint animation

// Phases for the draggable-slider caret. The order is the cycle order:
// idle → pulse → hold → idle … The `idle` arrival uses a long, no-op
// animation (hold and idle share the same scale/opacity) which produces
// the pause between pulses.
private enum SliderHintPhase: CaseIterable {
    case idle, pulse, hold

    var scale: CGFloat {
        switch self {
        case .idle, .hold: return 1.0
        case .pulse: return 1.35
        }
    }

    var opacity: Double {
        switch self {
        case .idle, .hold: return 0.65
        case .pulse: return 1.0
        }
    }

    var animation: Animation {
        switch self {
        case .pulse: return .easeOut(duration: 0.47)
        case .hold: return .easeIn(duration: 0.47)
        case .idle: return .linear(duration: 2.13)
        }
    }
}

// Continuous attention pulse for the LOWEST/HIGHEST split shares so users
// register them as the live readout. Shares the exact idle → pulse → hold →
// idle timing of the drag caret (SliderHintPhase) so the two throb in sync,
// with a gentler scale so the numbers don't fight the numeric roll.
private enum SplitSharePulsePhase: CaseIterable {
    case idle, pulse, hold

    var scale: CGFloat {
        switch self {
        case .idle, .hold: return 1.0
        case .pulse: return 1.18
        }
    }

    var opacity: Double {
        switch self {
        case .idle, .hold: return 0.8
        case .pulse: return 1.0
        }
    }

    var animation: Animation {
        switch self {
        case .pulse: return .easeOut(duration: 0.47)
        case .hold: return .easeIn(duration: 0.47)
        case .idle: return .linear(duration: 2.13)
        }
    }
}

private extension View {
    func splitSharePulse() -> some View {
        phaseAnimator(SplitSharePulsePhase.allCases) { content, phase in
            content
                .scaleEffect(phase.scale)
                .opacity(phase.opacity)
        } animation: { phase in
            phase.animation
        }
    }
}

// MARK: - Snapshots and caches

private struct SliderTrackSegment {
    let start: Double
    let end: Double
    let color: Color
}

private struct RaceEngineerSnapshot: Sendable {
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

    func matches(_ snap: RaceEngineerSnapshot) -> Bool {
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
    let sortedSnapshots: [RaceEngineerSnapshot]
    let fieldRanges: [String: FieldRange]

    static func compute(
        snapshots: [RaceEngineerSnapshot],
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
// baked into the analysis input. `normalizedDeltas` is now exposed so the
// comparison rows can render proportional delta bars without redoing the
// math.
private struct PanelCache: Sendable {
    let totalSessions: Int
    let splitIndex: Int
    let leftOutcomeAvg: Double?
    let rightOutcomeAvg: Double?
    let fieldOrder: [String]
    let leftAverages: [String: Double]
    let rightAverages: [String: Double]
    let normalizedDeltas: [String: Double]

    static func compute(from analysis: AnalysisCache, sliderPosition: Double) -> PanelCache {
        let total = analysis.sortedSnapshots.count
        let split = min(max(0, Int(round(sliderPosition * Double(total)))), total)
        let leftSlice = Array(analysis.sortedSnapshots.prefix(split))
        let rightSlice = Array(analysis.sortedSnapshots.suffix(total - split))

        func avg(_ slice: [RaceEngineerSnapshot], for name: String) -> Double? {
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
        // descending sort order — and so the comparison row's delta bar
        // can be sized consistently regardless of metric units.
        var normalizedDeltas: [String: Double] = [:]
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
            normalizedDeltas[name] = normalized
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
            rightAverages: rightAverages,
            normalizedDeltas: normalizedDeltas
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
