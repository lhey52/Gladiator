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
    @State private var showingOutcomeTooltip: Bool = false
    @State private var result: RaceEngineerOutcome?
    @State private var isAnalyzing: Bool = false
    @State private var showingPaywall: Bool = false
    @State private var isInitialLoading: Bool = true

    @ObservedObject private var iap = IAPManager.shared

    private var plottableFields: [CustomField] {
        allFields.filter { $0.fieldType.isPlottable }
    }

    private var filteredSessions: [Session] {
        filter.apply(to: sessions)
    }

    private var candidatePredictors: [String] {
        plottableFields.map(\.name).filter { $0 != outcome }
    }

    private var fieldTypeMap: [String: FieldType] {
        Dictionary(uniqueKeysWithValues: plottableFields.map { ($0.name, $0.fieldType) })
    }

    private var canAnalyze: Bool {
        !outcome.isEmpty && candidatePredictors.count >= 1 && !isAnalyzing
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
                    .dismissKeyboardOnTap()
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
                RaceEngineerFieldPicker(
                    title: "Select Outcome",
                    fields: plottableFields,
                    selected: outcome
                ) { name in
                    setOutcome(name)
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
        if plottableFields.count < 2 {
            emptyState(
                icon: "chart.line.flattrend.xyaxis",
                headline: "ADD 2+ METRICS",
                message: "Race Engineer needs at least 2 Number or Time metrics. Add more in Settings to unlock automatic setup analysis."
            )
        } else {
            ScrollView {
                VStack(spacing: 18) {
                    ToolDescriptionCard(text: "Race Engineer runs best subset selection across every Number and Time metric you log to automatically identify the combination with the strongest predictive power for your chosen metric. It then returns actionable, range-based setup targets drawn from your session history.")
                    outcomeCard
                    analyzeButton
                    resultSection
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
            HStack(spacing: 6) {
                Text("Select a metric analyze or improve:")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.5)
                    .foregroundColor(Theme.accent)
                Button {
                    showingOutcomeTooltip = true
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Theme.accent)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingOutcomeTooltip) {
                    Text("Best results come from choosing performance or condition outcomes, such as Race Time or Tire Temperature, rather than direct setup inputs you directly control, such as Tire Pressure or Fuel Load.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                        .padding(16)
                        .frame(width: 260)
                        .fixedSize(horizontal: false, vertical: true)
                        .presentationCompactAdaptation(.popover)
                        .presentationBackground(Theme.surface)
                }
                Spacer()
            }

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

            Text("Race Engineer will test every combination of your other \(candidatePredictors.count) Number and Time metric\(candidatePredictors.count == 1 ? "" : "s") (up to \(BestSubsetEngine.maxSubsetSize) at once) and pick the combination with the highest Adjusted R².")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.textTertiary)
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

    // MARK: - Analyze button

    private var analyzeButton: some View {
        Button {
            runAnalysis()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 13, weight: .heavy))
                Text(isAnalyzing ? "ANALYZING…" : "ANALYZE")
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
                Text("Searching the best combination of metrics for \(outcome)…")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Result section

    @ViewBuilder
    private var resultSection: some View {
        switch result {
        case .none:
            EmptyView()
        case .success(let r):
            RaceEngineerResultCard(result: r)
        case .insufficientData(let n, let minimum):
            warningCard(
                icon: "exclamationmark.triangle",
                headline: "NOT ENOUGH DATA",
                message: "Race Engineer needs at least \(minimum) session\(minimum == 1 ? "" : "s") per predictor to produce reliable results. You currently have \(n) session\(n == 1 ? "" : "s") with this outcome recorded. Add more sessions or relax your filters to run this analysis."
            )
        case .insufficientCandidates:
            warningCard(
                icon: "exclamationmark.triangle",
                headline: "NOT ENOUGH METRICS",
                message: "Race Engineer needs at least one other Number or Time metric besides the outcome. Add more metrics in Settings."
            )
        case .noVariance:
            warningCard(
                icon: "exclamationmark.triangle",
                headline: "NO VARIATION",
                message: "The outcome has the same value in every analyzed session — there is nothing to predict. Add sessions with different outcome values."
            )
        }
    }

    private func warningCard(icon: String, headline: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.8))
            Text(headline)
                .font(.system(size: 14, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.textPrimary)
            Text(message)
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
        outcome = name
        result = nil
    }

    private func runAnalysis() {
        guard canAnalyze else { return }
        let outcomeName = outcome
        let outcomeFieldType = plottableFields.first { $0.name == outcomeName }?.fieldType ?? .number
        let predictors = candidatePredictors
        let typeMap = fieldTypeMap
        let sessionsSnapshot = filteredSessions

        result = nil
        withAnimation(.easeInOut(duration: 0.2)) { isAnalyzing = true }

        Task.detached(priority: .userInitiated) {
            let outcomeCase = BestSubsetEngine.analyze(
                sessions: sessionsSnapshot,
                outcome: outcomeName,
                outcomeFieldType: outcomeFieldType,
                candidatePredictors: predictors,
                fieldTypes: typeMap
            )
            await MainActor.run {
                result = outcomeCase
                withAnimation(.easeInOut(duration: 0.2)) { isAnalyzing = false }
            }
        }
    }
}

// MARK: - Result card

private struct RaceEngineerResultCard: View {
    let result: RaceEngineerResult

    @State private var isModelSummaryExpanded: Bool = false
    @State private var isContributorsExpanded: Bool = false
    @State private var isRecommendationsExpanded: Bool = false
    @State private var isDataSufficiencyExpanded: Bool = false

    private var adjustedRSquaredPercent: Int {
        Int((result.adjustedRSquared * 100).rounded())
    }

    private func sectionHeader(
        title: String,
        systemImage: String,
        isExpanded: Bool,
        toggle: @escaping () -> Void
    ) -> some View {
        Button(action: toggle) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.5)
                    .foregroundColor(Theme.accent)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(Theme.accent)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headlineSection
            Divider().background(Theme.hairline)
            modelSummarySection
            Divider().background(Theme.hairline)
            contributorsSection
            Divider().background(Theme.hairline)
            recommendationsSection
            Divider().background(Theme.hairline)
            dataSufficiencySection
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.accent.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: Theme.accent.opacity(0.15), radius: 16)
    }

    // MARK: - Headline

    private var headlineSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MODEL PREDICTIVE POWER")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(Theme.textSecondary)
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(adjustedRSquaredPercent)")
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.accent)
                Text("%")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.accent)
            }
            Text("Race Engineer has identified \(result.predictors.count) metric\(result.predictors.count == 1 ? "" : "s") that together appear to influence approximately \(adjustedRSquaredPercent)% of your \(result.outcome). The remaining \(100 - adjustedRSquaredPercent)% of variation lies outside your current tracked data.")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Section 1 — Model Summary

    private var modelSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "MODEL SUMMARY",
                systemImage: "sparkles",
                isExpanded: isModelSummaryExpanded
            ) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isModelSummaryExpanded.toggle()
                }
            }

            if isModelSummaryExpanded {
                Text(modelSummaryText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var modelSummaryText: String {
        let n = result.predictors.count
        let names = result.contributors.map(\.name).joined(separator: ", ")
        let pct = adjustedRSquaredPercent
        var text = "The following \(n) metric\(n == 1 ? "" : "s") when combined currently have the highest predictive power for \(result.outcome): \(names). In other words, of all the metrics you have logged so far, "
        if n == 1 {
            text += "this metric "
        } else {
            text += "these \(n) metrics acting together "
        }
        text += "appear to have the greatest "
        if n == 1 { text += "influence on \(result.outcome)" }
        else { text += "combined influence on \(result.outcome)" }
        text += ". Together they account for \(pct)% of the observed variation in \(result.outcome) across \(result.sampleSize) session\(result.sampleSize == 1 ? "" : "s")\(contextSuffix)."
        if result.adjustedRSquared < 0.20 {
            text += " While this may seem low, even a small improvement in \(result.outcome) can provide a meaningful edge — and as more sessions are logged this figure may increase."
        }
        return text
    }

    private var contextSuffix: String {
        var suffix = ""
        if result.tracks.count == 1, let track = result.tracks.first, !track.isEmpty {
            suffix += " at \(track)"
        }
        if result.vehicles.count == 1, let vehicle = result.vehicles.first, !vehicle.isEmpty {
            suffix += " in \(vehicle)"
        }
        return suffix
    }

    // MARK: - Section 2 — Contributors

    private var contributorsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "METRIC CONTRIBUTORS (\(result.contributors.count))",
                systemImage: "chart.bar.fill",
                isExpanded: isContributorsExpanded
            ) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isContributorsExpanded.toggle()
                }
            }

            if isContributorsExpanded {
                Text("The following \(result.contributors.count) metric\(result.contributors.count == 1 ? "" : "s") \(result.contributors.count == 1 ? "was" : "were") isolated amongst a grouping of up to 15 combined metrics and returned the highest predictive power for \(result.outcome):")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(Array(result.contributors.enumerated()), id: \.element.id) { index, contributor in
                    contributorRow(contributor: contributor, isTop: index == 0)
                }

                Text("Each metric's contribution is its share of the model's explanatory power. Absolute contribution (share × Adjusted R²) is the portion of overall \(result.outcome) variation attributable to that metric, assuming the others in the model are held fixed.")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Theme.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func contributorRow(contributor: RaceEngineerContributor, isTop: Bool) -> some View {
        let share = max(0, min(1, contributor.sharePercent / 100))
        // absolutePct is the share of outcome variation attributable to this
        // predictor alone: (share of model) × (Adjusted R² of model), expressed
        // as a 0–100 percentage for display.
        let absolutePct = contributor.sharePercent * result.adjustedRSquared
        let absoluteCopy: String
        if isTop {
            absoluteCopy = "\(contributor.name) is the largest contributor at \(formatShare(contributor.sharePercent)) of the model, meaning it accounts for approximately \(formatShare(absolutePct)) of \(result.outcome) variation — your largest single lever on performance in this dataset."
        } else {
            absoluteCopy = "Accounts for approximately \(formatShare(absolutePct)) of \(result.outcome) variation — \(rankDescription(for: contributor))."
        }
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(contributor.name.uppercased())
                    .font(.system(size: 13, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                Spacer()
                Text(String(format: "%.0f%%", contributor.sharePercent))
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.accent)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Theme.surfaceElevated)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Theme.accent)
                        .frame(width: max(geo.size.width * CGFloat(share), 2), height: 6)
                        .shadow(color: Theme.accent.opacity(0.5), radius: 4)
                }
            }
            .frame(height: 6)

            directionRow(contributor: contributor)

            if let perUnit = perUnitInsight(for: contributor) {
                insightBullet(text: perUnit)
            }

            insightBullet(text: absoluteCopy)

            insightBullet(text: "Observed range in your sessions: \(formatValue(contributor.observedMin, contributor: contributor)) to \(formatValue(contributor.observedMax, contributor: contributor))\(unitSuffix(contributor.unit))")
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isTop ? Theme.accent.opacity(0.35) : Theme.hairline, lineWidth: 1)
        )
    }

    private func directionRow(contributor: RaceEngineerContributor) -> some View {
        HStack(spacing: 8) {
            Image(systemName: directionIcon(for: contributor))
                .font(.system(size: 11, weight: .heavy))
                .foregroundColor(Theme.accent)
            Text(directionText(for: contributor))
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func directionText(for contributor: RaceEngineerContributor) -> String {
        guard contributor.hasClearDirection else {
            return "Direction uncertain in this dataset — mixed effect on \(result.outcome)."
        }
        let outcomeBetter: String
        switch result.outcomeFieldType {
        case .time: outcomeBetter = "lower \(result.outcome)"
        case .number: outcomeBetter = "higher \(result.outcome)"
        case .text: outcomeBetter = "better \(result.outcome)"
        }
        // Standardized coefficient sign tells us whether predictor pushes
        // outcome up or down. Combine with outcome's "better direction" to
        // phrase whether higher predictor values are good or bad.
        let pushesOutcomeDown = contributor.standardizedCoefficient < 0
        let higherIsBetter: Bool
        switch result.outcomeFieldType {
        case .time: higherIsBetter = pushesOutcomeDown
        case .number: higherIsBetter = !pushesOutcomeDown
        case .text: higherIsBetter = !pushesOutcomeDown
        }
        let directionWord = higherIsBetter ? "Higher" : "Lower"
        return "\(directionWord) values associated with \(outcomeBetter)."
    }

    private func directionIcon(for contributor: RaceEngineerContributor) -> String {
        guard contributor.hasClearDirection else { return "arrow.left.arrow.right" }
        let pushesOutcomeDown = contributor.standardizedCoefficient < 0
        let higherIsBetter: Bool
        switch result.outcomeFieldType {
        case .time: higherIsBetter = pushesOutcomeDown
        case .number: higherIsBetter = !pushesOutcomeDown
        case .text: higherIsBetter = !pushesOutcomeDown
        }
        return higherIsBetter ? "arrow.up.right" : "arrow.down.right"
    }

    private func insightBullet(text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Theme.accent.opacity(0.7))
                .frame(width: 4, height: 4)
                .padding(.top, 6)
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func rankDescription(for contributor: RaceEngineerContributor) -> String {
        let idx = result.contributors.firstIndex(where: { $0.id == contributor.id }) ?? 0
        switch idx {
        case 1: return "your 2nd largest lever on \(result.outcome)"
        case 2: return "your 3rd largest lever on \(result.outcome)"
        default: return "a secondary lever on \(result.outcome)"
        }
    }

    private func perUnitInsight(for contributor: RaceEngineerContributor) -> String? {
        guard contributor.hasClearDirection else { return nil }
        let magnitude = abs(contributor.rawCoefficient)
        guard magnitude > 1e-9 else { return nil }
        let direction = contributor.rawCoefficient > 0 ? "increases" : "decreases"
        let predictorUnit = contributor.unit.isEmpty ? "unit" : contributor.unit
        let outcomeChange = formatOutcomeDelta(magnitude)
        return "For every 1 \(predictorUnit) increase in \(contributor.name), \(result.outcome) \(direction) by approximately \(outcomeChange)."
    }

    // MARK: - Section 3 — Setup Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "SETUP RECOMMENDATIONS",
                systemImage: "wrench.and.screwdriver.fill",
                isExpanded: isRecommendationsExpanded
            ) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isRecommendationsExpanded.toggle()
                }
            }

            if isRecommendationsExpanded {
                Text("For best results adjust one metric at a time across sessions so you can isolate the effect of each change. Start with your highest contributing metric first.")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Continue logging sessions as normal to improve the model and refine these recommendations over time.")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(result.contributors) { contributor in
                    recommendationRow(contributor: contributor)
                }

                Text("These are hypotheses to test on track, not guaranteed outcomes. Deliberately vary these values across sessions and use the Correlation and Trend tools to track the effect.")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(0.3)
                    .foregroundColor(Theme.accent.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.accent.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Theme.accent.opacity(0.4), lineWidth: 1)
                    )
            }
        }
    }

    private func recommendationRow(contributor: RaceEngineerContributor) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(contributor.name.uppercased())
                .font(.system(size: 12, weight: .heavy))
                .tracking(1)
                .foregroundColor(Theme.textPrimary)

            Text(recommendationText(for: contributor))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private func recommendationText(for contributor: RaceEngineerContributor) -> String {
        let trackPhrase = result.tracks.count == 1 ? " at \(result.tracks[0])" : ""
        let unit = unitSuffix(contributor.unit)

        // Case 3 — Insufficient variation in the predictor itself.
        if !contributor.hasMeaningfulVariation {
            return "Not enough variation in \(contributor.name) across your sessions to make a specific recommendation. Try deliberately varying this value across your next few sessions."
        }

        // Case 2 — Direction is present but top-session range doesn't discriminate
        // enough from the overall range to be actionable.
        if !contributor.hasClearDirection || !contributor.topSessionsDiscriminate {
            let higherIsBetter = impliedHigherIsBetter(for: contributor)
            let directionWord = higherIsBetter ? "Higher" : "Lower"
            let actionVerb = higherIsBetter ? "raising" : "lowering"
            return "\(directionWord) \(contributor.name) is associated with better \(result.outcome) in your data. Try \(actionVerb) from your current session average of \(formatValue(contributor.observedMean, contributor: contributor))\(unit) and observe the effect."
        }

        // Case 1 — Clear direction + informative top-session range.
        let rangeLow = formatValue(contributor.topSessionMin, contributor: contributor)
        let rangeHigh = formatValue(contributor.topSessionMax, contributor: contributor)
        let actionVerb = impliedHigherIsBetter(for: contributor) ? "raising" : "lowering"
        let avg = formatValue(contributor.observedMean, contributor: contributor)
        return "Target \(contributor.name) between \(rangeLow) and \(rangeHigh)\(unit) — this is the range seen in your \(contributor.topSessionCount) fastest session\(contributor.topSessionCount == 1 ? "" : "s")\(trackPhrase). Try \(actionVerb) from your current session average of \(avg)\(unit)."
    }

    private func impliedHigherIsBetter(for contributor: RaceEngineerContributor) -> Bool {
        guard contributor.hasClearDirection else { return true }
        let pushesOutcomeDown = contributor.standardizedCoefficient < 0
        switch result.outcomeFieldType {
        case .time: return pushesOutcomeDown
        case .number: return !pushesOutcomeDown
        case .text: return !pushesOutcomeDown
        }
    }

    // MARK: - Section 4 — Data Sufficiency

    private var dataSufficiencySection: some View {
        let k = max(result.predictors.count, 1)
        let currentSessions = result.sampleSize
        let goodTarget = RegressionEngine.highSessionsPerPredictor * k
        let excellentTarget = RegressionEngine.idealSessionsPerPredictor * k
        let needed = max(0, goodTarget - currentSessions)

        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "DATA SUFFICIENCY",
                systemImage: "square.stack.3d.up.fill",
                isExpanded: isDataSufficiencyExpanded
            ) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isDataSufficiencyExpanded.toggle()
                }
            }

            if isDataSufficiencyExpanded {
                DataSufficiencyBadge(level: result.dataSufficiency)

                Text(result.dataSufficiency.description(
                    sampleSize: result.sampleSize,
                    predictorCount: result.predictors.count
                ))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 0) {
                    sufficiencyRow(label: "Sessions analyzed", value: "\(currentSessions)")
                    Divider().background(Theme.hairline).padding(.leading, 14)
                    sufficiencyRow(label: "Predictors in model", value: "\(result.predictors.count)")
                    Divider().background(Theme.hairline).padding(.leading, 14)
                    sufficiencyRow(label: "Recommended for Good", value: "\(goodTarget)")
                    Divider().background(Theme.hairline).padding(.leading, 14)
                    sufficiencyRow(label: "Recommended for Excellent", value: "\(excellentTarget)")
                    if needed > 0 {
                        Divider().background(Theme.hairline).padding(.leading, 14)
                        sufficiencyRow(
                            label: "Still needed for Good",
                            value: "+\(needed) session\(needed == 1 ? "" : "s")",
                            emphasize: true
                        )
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surfaceElevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.hairline, lineWidth: 1)
                )

                Text("As more sessions are logged\(contextSuffix) the model may identify different optimal predictors and update these recommendations — particularly at Bad or Poor data sufficiency levels where results are most likely to change.")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func sufficiencyRow(label: String, value: String, emphasize: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .heavy))
                .foregroundColor(emphasize ? Theme.warning : Theme.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Formatting

    private func formatValue(_ value: Double, contributor: RaceEngineerContributor) -> String {
        switch contributor.fieldType {
        case .time:
            return TimeFormatting.secondsToDisplay(value)
        case .number:
            return formatNumber(value)
        case .text:
            return formatNumber(value)
        }
    }

    private func formatNumber(_ value: Double) -> String {
        let magnitude = abs(value)
        if magnitude >= 100 {
            return String(format: "%.1f", value)
        } else if magnitude >= 10 {
            return String(format: "%.2f", value)
        } else {
            return String(format: "%.3f", value)
        }
    }

    private func formatOutcomeDelta(_ magnitude: Double) -> String {
        let outcomeUnit = result.outcomeUnit.isEmpty ? "" : " \(result.outcomeUnit)"
        switch result.outcomeFieldType {
        case .time:
            if magnitude < 1 {
                let millis = magnitude * 1000
                return String(format: "%.0f ms", millis)
            }
            return "\(formatNumber(magnitude))\(outcomeUnit.isEmpty ? " s" : outcomeUnit)"
        case .number, .text:
            return "\(formatNumber(magnitude))\(outcomeUnit)"
        }
    }

    private func unitSuffix(_ unit: String) -> String {
        unit.isEmpty ? "" : " \(unit)"
    }

    private func formatShare(_ percent: Double) -> String {
        String(format: "%.0f%%", percent)
    }
}

// MARK: - Field picker sheet

private struct RaceEngineerFieldPicker: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let fields: [CustomField]
    let selected: String?
    let onSelect: (String) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                content
            }
            .navigationTitle(title)
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
