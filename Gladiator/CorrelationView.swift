//
//  CorrelationView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct CorrelationView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var iap = IAPManager.shared
    @Query(sort: [SortDescriptor(\CustomField.sortOrder)])
    private var allFields: [CustomField]
    @Query(sort: [SortDescriptor(\Session.date, order: .reverse)])
    private var sessions: [Session]

    @AppStorage("correlationFieldA") private var storedFieldA: String = ""
    @AppStorage("correlationFieldB") private var storedFieldB: String = ""

    @State private var showingPickerA: Bool = false
    @State private var showingPickerB: Bool = false
    @State private var showingPaywall: Bool = false
    @State private var filter = AnalyticsFilterState()
    @State private var showingFilter: Bool = false
    @State private var isLoading: Bool = true

    private var plottableFields: [CustomField] {
        allFields.filter { $0.fieldType.isPlottable }
    }

    private var fieldAName: String {
        resolved(storedFieldA, fallback: 0)
    }

    private var fieldBName: String {
        resolved(storedFieldB, fallback: 1)
    }

    private var canCalculate: Bool {
        !fieldAName.isEmpty && !fieldBName.isEmpty && fieldAName != fieldBName
    }

    private var filteredSessions: [Session] {
        filter.apply(to: sessions)
    }

    private var result: CorrelationResult? {
        guard canCalculate else { return nil }
        return CorrelationEngine.calculate(sessions: filteredSessions, fieldA: fieldAName, fieldB: fieldBName)
    }

    var body: some View {
        if isLoading {
            AnalyticsLoadingView(
                toolName: "Correlation Analysis",
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
            .navigationTitle("Correlation Analysis")
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
                fieldSelectors
                ZStack {
                    VStack(spacing: 20) {
                        ToolDescriptionCard(text: "Measure the statistical relationship between two metrics across your sessions. Select two fields to compare — the tool calculates the Pearson coefficient, rates the strength and direction, and flags how reliable the result is based on sample size.")
                        resultSection
                        disclaimer
                    }
                    .blur(radius: iap.isProUser ? 0 : 6)
                    .allowsHitTesting(iap.isProUser)

                    if !iap.isProUser {
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
                        }
                    }
                }
            }
            .padding(20)
        }
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    // MARK: - Field selectors

    private var fieldSelectors: some View {
        VStack(spacing: 12) {
            selectorButton(label: "FIELD A", fieldName: fieldAName) {
                showingPickerA = true
            }
            .sheet(isPresented: $showingPickerA) {
                correlationFieldPicker(axis: "Field A", current: fieldAName) { name in
                    storedFieldA = name
                    showingPickerA = false
                }
            }

            selectorButton(label: "FIELD B", fieldName: fieldBName) {
                showingPickerB = true
            }
            .sheet(isPresented: $showingPickerB) {
                correlationFieldPicker(axis: "Field B", current: fieldBName) { name in
                    storedFieldB = name
                    showingPickerB = false
                }
            }

            if !canCalculate && plottableFields.count >= 2 {
                Text("SELECT TWO DIFFERENT FIELDS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(Theme.textTertiary)
                    .padding(.top, 4)
            }
        }
    }

    private func selectorButton(label: String, fieldName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(label)
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.background)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Theme.accent))
                Text(fieldName.isEmpty ? "SELECT FIELD" : fieldName.uppercased())
                    .font(.system(size: 14, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Result

    @ViewBuilder
    private var resultSection: some View {
        if plottableFields.count < 2 {
            emptyState
        } else if let result {
            if result.sampleSize < CorrelationEngine.minimumSessions {
                insufficientData(result.sampleSize)
            } else {
                resultCard(result)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.6))
            Text("ADD 2+ NUMBER OR TIME METRICS IN SETTINGS")
                .font(.system(size: 12, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func insufficientData(_ count: Int) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.7))
            Text("NOT ENOUGH DATA")
                .font(.system(size: 14, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.textPrimary)
            Text("At least \(CorrelationEngine.minimumSessions) sessions with both fields recorded are needed for a reliable correlation. Currently \(count).")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface)
        )
    }

    private func resultCard(_ result: CorrelationResult) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            rValueSection(result)
            Divider().background(Theme.hairline)
            HStack {
                strengthSection(result)
                Spacer()
                confidenceBadge(result.confidence)
            }
            Divider().background(Theme.hairline)
            insightSection(result)
            sampleSection(result)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(result.strength.color.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: result.strength.color.opacity(0.15), radius: 16)
    }

    private func rValueSection(_ result: CorrelationResult) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PEARSON COEFFICIENT (r)")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Theme.textSecondary)
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(String(format: "%+.2f", result.r))
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                rBar(result.r)
            }
        }
    }

    private func rBar(_ r: Double) -> some View {
        GeometryReader { geo in
            let width = geo.size.width
            let center = width / 2
            let magnitude = CGFloat(abs(r)) * center
            let barStart = r >= 0 ? center : center - magnitude
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Theme.hairline)
                    .frame(height: 6)
                Rectangle()
                    .fill(CorrelationStrength.from(r: r).color)
                    .frame(width: magnitude, height: 6)
                    .offset(x: barStart)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                Rectangle()
                    .fill(Theme.textTertiary)
                    .frame(width: 1, height: 12)
                    .offset(x: center)
            }
        }
        .frame(height: 12)
    }

    private func strengthSection(_ result: CorrelationResult) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(result.strength.color)
                .frame(width: 10, height: 10)
                .shadow(color: result.strength.color.opacity(0.5), radius: 4)
            Text(result.strength.label.uppercased())
                .font(.system(size: 12, weight: .heavy))
                .tracking(1)
                .foregroundColor(result.strength.color)
        }
    }

    private func confidenceBadge(_ confidence: CorrelationConfidence) -> some View {
        HStack(spacing: 5) {
            Image(systemName: confidence.systemImage)
                .font(.system(size: 11, weight: .bold))
            Text(confidence.label.uppercased())
                .font(.system(size: 10, weight: .heavy))
                .tracking(1)
        }
        .foregroundColor(confidence.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(confidence.color.opacity(0.12))
        )
        .overlay(
            Capsule().stroke(confidence.color.opacity(0.4), lineWidth: 1)
        )
    }

    private func insightSection(_ result: CorrelationResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("INSIGHT", systemImage: "lightbulb.fill")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Theme.accent)
            Text(result.insight)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func sampleSection(_ result: CorrelationResult) -> some View {
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

    // MARK: - Disclaimer

    private var disclaimer: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.textTertiary)
            Text("Correlation requires sufficient data to be meaningful. More sessions improve confidence and accuracy.")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.surface.opacity(0.6))
        )
    }

    // MARK: - Picker

    private func correlationFieldPicker(axis: String, current: String, onSelect: @escaping (String) -> Void) -> some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(plottableFields) { field in
                            Button {
                                onSelect(field.name)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: field.fieldType.systemImage)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Theme.accent)
                                    Text(field.name)
                                        .font(.system(size: 15, weight: .heavy))
                                        .foregroundColor(Theme.textPrimary)
                                    Spacer()
                                    if field.name == current {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(Theme.accent)
                                    }
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(field.name == current ? Theme.accent.opacity(0.1) : Theme.surface)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(field.name == current ? Theme.accent.opacity(0.5) : Theme.hairline, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(axis)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if axis == "Field A" {
                            showingPickerA = false
                        } else {
                            showingPickerB = false
                        }
                    }
                    .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func resolved(_ stored: String, fallback: Int) -> String {
        if !stored.isEmpty, plottableFields.contains(where: { $0.name == stored }) {
            return stored
        }
        guard plottableFields.count > fallback else { return "" }
        return plottableFields[fallback].name
    }
}

#Preview {
    CorrelationView()
        .modelContainer(for: [Session.self, CustomField.self, FieldValue.self], inMemory: true)
}
