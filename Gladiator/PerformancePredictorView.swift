//
//  PerformancePredictorView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct PerformancePredictorView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\CustomField.sortOrder)])
    private var allFields: [CustomField]
    @Query(sort: [SortDescriptor(\Session.date, order: .reverse)])
    private var sessions: [Session]

    @State private var outcome: String = ""
    @State private var predictors: [String] = []
    @State private var filter = AnalyticsFilterState()
    @State private var showingFilter: Bool = false
    @State private var showingOutcomePicker: Bool = false
    @State private var showingAddPredictor: Bool = false
    @State private var result: PredictiveAnalysisOutcome?
    @State private var showingPaywall: Bool = false
    @State private var activeTooltip: TooltipKind?
    @ObservedObject private var iap = IAPManager.shared
    @AppStorage("hasOpenedPerformancePredictor") private var hasOpenedPredictor: Bool = false

    private enum TooltipKind {
        case outcome
        case predictors

        var message: String {
            switch self {
            case .outcome:
                return "Select the metric you want to predict. The analysis will show how well your chosen predictors explain changes in this metric."
            case .predictors:
                return "Add up to 5 predictor metrics using the button below. These are the metrics you want to test as potential influences on your outcome metric."
            }
        }
    }

    private func tooltipBinding(for kind: TooltipKind) -> Binding<Bool> {
        Binding(
            get: { activeTooltip == kind },
            set: { activeTooltip = $0 ? kind : nil }
        )
    }

    private func tooltipTrigger(for kind: TooltipKind) -> some View {
        Button {
            activeTooltip = kind
        } label: {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.accent)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: tooltipBinding(for: kind)) {
            Text(kind.message)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .padding(16)
                .frame(width: 260)
                .fixedSize(horizontal: false, vertical: true)
                .presentationCompactAdaptation(.popover)
                .presentationBackground(Theme.surface)
        }
    }

    private var plottableFields: [CustomField] {
        allFields.filter { $0.fieldType.isPlottable }
    }

    private var filteredSessions: [Session] {
        filter.apply(to: sessions)
    }

    private var availableForOutcome: [CustomField] {
        plottableFields.filter { !predictors.contains($0.name) }
    }

    private var availableForPredictor: [CustomField] {
        plottableFields.filter { $0.name != outcome && !predictors.contains($0.name) }
    }

    private var canCalculate: Bool {
        !outcome.isEmpty && !predictors.isEmpty
    }

    private var canAddPredictor: Bool {
        predictors.count < RegressionEngine.maxPredictors && !availableForPredictor.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                    .dismissKeyboardOnTap()
                lockedContent
            }
            .navigationTitle("Performance Predictor")
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
                FieldPickerSheet(
                    title: "Select Outcome",
                    fields: availableForOutcome,
                    selected: outcome
                ) { name in
                    setOutcome(name)
                }
            }
            .sheet(isPresented: $showingAddPredictor) {
                FieldPickerSheet(
                    title: "Add Predictor",
                    fields: availableForPredictor,
                    selected: nil
                ) { name in
                    addPredictor(name)
                }
            }
            .fullScreenCover(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if !hasOpenedPredictor { hasOpenedPredictor = true }
        }
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

    // MARK: - Main content

    @ViewBuilder
    private var mainContent: some View {
        if plottableFields.count < 2 {
            emptyState(
                icon: "chart.line.flattrend.xyaxis",
                headline: "ADD 2+ METRICS",
                message: "Add at least 2 Number or Time metrics in Settings to build a predictive model."
            )
        } else {
            ScrollView {
                VStack(spacing: 18) {
                    ToolDescriptionCard(text: "Discover which metrics most influence your performance. Select an outcome to predict and up to five predictors, then tap Calculate. The tool runs a multiple linear regression and ranks each predictor by its relative contribution to the model.")
                    outcomeCard
                    predictorsCard
                    calculateButton
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
                Text("OUTCOME (WHAT YOU WANT TO PREDICT)")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.5)
                    .foregroundColor(Theme.accent)
                tooltipTrigger(for: .outcome)
                Spacer(minLength: 0)
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

    // MARK: - Predictors card

    private var predictorsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("PREDICTORS (WHAT INFLUENCES IT)")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.5)
                    .foregroundColor(Theme.accent)
                tooltipTrigger(for: .predictors)
                Spacer()
                Text("\(predictors.count) / \(RegressionEngine.maxPredictors)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.textTertiary)
            }

            if predictors.isEmpty {
                Text("No predictors selected, add some below")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surfaceElevated)
                    )
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(predictors.enumerated()), id: \.offset) { index, name in
                        predictorRow(name: name, index: index)
                    }
                }
            }

            Button {
                showingAddPredictor = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .heavy))
                    Text("ADD PREDICTOR")
                        .font(.system(size: 12, weight: .heavy))
                        .tracking(1.2)
                }
                .foregroundColor(canAddPredictor ? Theme.accent : Theme.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(canAddPredictor ? Theme.accent.opacity(0.12) : Theme.surfaceElevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(canAddPredictor ? Theme.accent.opacity(0.4) : Theme.hairline, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(!canAddPredictor)
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

    private func predictorRow(name: String, index: Int) -> some View {
        let field = plottableFields.first(where: { $0.name == name })
        return HStack(spacing: 10) {
            Image(systemName: field?.fieldType.systemImage ?? "number")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Theme.accent)
            Text(name.uppercased())
                .font(.system(size: 14, weight: .heavy))
                .tracking(1)
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
            Spacer()
            Button { removePredictor(at: index) } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Calculate button

    private var calculateButton: some View {
        Button {
            calculate()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 13, weight: .heavy))
                Text("CALCULATE")
                    .font(.system(size: 14, weight: .heavy))
                    .tracking(1.5)
            }
            .foregroundColor(canCalculate ? Theme.background : Theme.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(canCalculate ? Theme.accent : Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(canCalculate ? Theme.accent : Theme.hairline, lineWidth: 1)
            )
            .shadow(color: canCalculate ? Theme.accent.opacity(0.4) : .clear, radius: 12)
        }
        .buttonStyle(.plain)
        .disabled(!canCalculate)
    }

    // MARK: - Result section

    @ViewBuilder
    private var resultSection: some View {
        switch result {
        case .none:
            EmptyView()
        case .success(let r):
            ResultCard(result: r)
        case .insufficientData(let n, let k):
            insufficientDataCard(sampleSize: n, predictorCount: k)
        case .singularMatrix(let n):
            singularMatrixCard(sampleSize: n)
        case .noVariance:
            noVarianceCard
        }
    }

    private func insufficientDataCard(sampleSize: Int, predictorCount: Int) -> some View {
        let sessionWord = sampleSize == 1 ? "session" : "sessions"
        let predictorWord = predictorCount == 1 ? "predictor" : "predictors"
        return warningCard(
            icon: "exclamationmark.triangle",
            headline: "NOT ENOUGH DATA",
            message: "Performance Predictor needs at least \(RegressionEngine.sessionsPerPredictor) sessions per predictor to produce reliable results. You have \(sampleSize) \(sessionWord) for \(predictorCount) \(predictorWord) — add more sessions or reduce the predictor count."
        )
    }

    private func singularMatrixCard(sampleSize: Int) -> some View {
        let sessionWord = sampleSize == 1 ? "session" : "sessions"
        return warningCard(
            icon: "exclamationmark.triangle",
            headline: "UNSTABLE MODEL",
            message: "The selected predictors are too redundant or one has no variation across the \(sampleSize) analyzed \(sessionWord) — the model cannot separate their effects. Remove a predictor or add more diverse sessions."
        )
    }

    private var noVarianceCard: some View {
        warningCard(
            icon: "exclamationmark.triangle",
            headline: "NO VARIATION",
            message: "The outcome has the same value in every analyzed session — there is nothing to predict. Add sessions with different outcome values."
        )
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
        predictors.removeAll { $0 == name }
        result = nil
    }

    private func addPredictor(_ name: String) {
        guard predictors.count < RegressionEngine.maxPredictors,
              !predictors.contains(name),
              name != outcome else { return }
        predictors.append(name)
        result = nil
    }

    private func removePredictor(at index: Int) {
        guard predictors.indices.contains(index) else { return }
        predictors.remove(at: index)
        result = nil
    }

    private func calculate() {
        result = RegressionEngine.analyze(
            sessions: filteredSessions,
            outcome: outcome,
            predictors: predictors
        )
    }
}

// MARK: - Result card

private struct ResultCard: View {
    let result: PredictiveAnalysisResult

    private var powerLevel: PredictivePowerLevel {
        PredictivePowerLevel.from(adjustedRSquared: result.adjustedRSquared)
    }

    private var adjustedRSquaredPercent: Int {
        Int((result.adjustedRSquared * 100).rounded())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            predictivePowerSection
            Divider().background(Theme.hairline)
            headlineSection
            Divider().background(Theme.hairline)
            contributionSection
            Divider().background(Theme.hairline)
            summarySection
            sampleSection
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

    private var predictivePowerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ADJUSTED PREDICTIVE POWER")
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
            Text("of variation in \(result.outcome) is explained by your selected predictors")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var headlineSection: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Theme.accent)
                .frame(width: 10, height: 10)
                .shadow(color: Theme.accent.opacity(0.5), radius: 4)
            Text(powerLevel.headline(outcome: result.outcome))
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var contributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("CONTRIBUTION BREAKDOWN", systemImage: "chart.bar.fill")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(Theme.accent)

            VStack(spacing: 10) {
                ForEach(result.contributions) { contribution in
                    contributionRow(contribution)
                }
            }
        }
    }

    private func contributionRow(_ contribution: PredictorContribution) -> some View {
        let share = max(0, min(1, contribution.sharePercent / 100))
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(contribution.name.uppercased())
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                Spacer()
                Text(String(format: "%.0f%%", contribution.sharePercent))
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
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
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("SUMMARY", systemImage: "text.alignleft")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(Theme.accent)
            Text(RegressionEngine.plainEnglishSummary(result: result))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var sampleSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Theme.textTertiary)
            Text("\(result.sampleSize) sessions analyzed")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.8)
                .foregroundColor(Theme.textTertiary)
        }
    }
}

// MARK: - Field picker sheet

private struct FieldPickerSheet: View {
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
    PerformancePredictorView()
        .modelContainer(for: [Session.self, CustomField.self, FieldValue.self, Track.self, Vehicle.self], inMemory: true)
}
