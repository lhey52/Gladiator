//
//  CorrelationMatrixView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct CorrelationMatrixView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\CustomField.sortOrder)])
    private var allFields: [CustomField]
    @Query(sort: [SortDescriptor(\Session.date, order: .reverse)])
    private var sessions: [Session]

    @State private var filter = AnalyticsFilterState()
    @State private var showingFilter: Bool = false
    @State private var selectedPair: MatrixPairSelection?
    @State private var showingPaywall: Bool = false
    @State private var isLoading: Bool = true
    @ObservedObject private var iap = IAPManager.shared

    private let cellSize: CGFloat = 64
    private let rowHeaderWidth: CGFloat = 108

    private var plottableFields: [CustomField] {
        allFields.filter { $0.fieldType.isPlottable }
    }

    private var filteredSessions: [Session] {
        filter.apply(to: sessions)
    }

    private var pairResults: [CorrelationPairResult] {
        BackgroundCorrelationScanner.scanPairs(sessions: filteredSessions, fields: allFields)
    }

    private var pairLookup: [String: CorrelationPairResult] {
        var map: [String: CorrelationPairResult] = [:]
        for result in pairResults {
            map[Self.pairKey(result.fieldA, result.fieldB)] = result
        }
        return map
    }

    private var hasAnyResults: Bool {
        !pairResults.isEmpty
    }

    var body: some View {
        if isLoading {
            AnalyticsLoadingView(
                toolName: "Correlation Matrix",
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
                lockedContent
            }
            .navigationTitle("Correlation Matrix")
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
            .sheet(item: $selectedPair) { pair in
                CorrelationPairDetailView(
                    fieldAName: pair.fieldA,
                    fieldBName: pair.fieldB,
                    sessions: filteredSessions
                )
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

    // MARK: - Main content

    @ViewBuilder
    private var mainContent: some View {
        if plottableFields.count < 2 {
            emptyState(
                icon: "tablecells",
                headline: "ADD 2+ METRICS",
                message: "Add at least 2 Number or Time metrics in Settings to generate a correlation matrix."
            )
        } else if !hasAnyResults {
            emptyState(
                icon: "tablecells",
                headline: "NOT ENOUGH DATA",
                message: "Record at least \(BackgroundCorrelationScanner.minimumSessions) sessions with values for at least one pair of metrics."
            )
        } else {
            ScrollView {
                VStack(spacing: 20) {
                    ToolDescriptionCard(text: "Scan correlations between every pair of your plottable metrics at once on a color-coded grid. Orange cells signal positive relationships, blue cells signal negative, and neutral tones indicate weak or no relationship. Tap any colored cell for a full breakdown of that pair.")
                    matrixCard
                    legendCard
                    footerNote
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

    // MARK: - Matrix card

    private var matrixCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HEAT MAP")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.8)
                .foregroundColor(Theme.accent)
                .padding(.leading, 4)

            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                matrixGrid
                    .padding(8)
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
        }
    }

    private var matrixGrid: some View {
        VStack(spacing: 1) {
            headerRow
            ForEach(plottableFields) { rowField in
                dataRow(for: rowField)
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 1) {
            Color.clear
                .frame(width: rowHeaderWidth, height: cellSize)

            ForEach(plottableFields) { colField in
                columnHeaderCell(name: colField.name)
            }
        }
    }

    private func columnHeaderCell(name: String) -> some View {
        Text(name.uppercased())
            .font(.system(size: 10, weight: .heavy))
            .tracking(0.8)
            .foregroundColor(Theme.textSecondary)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .frame(width: cellSize, height: cellSize)
            .background(Theme.surfaceElevated)
    }

    private func rowHeaderCell(name: String) -> some View {
        HStack {
            Text(name.uppercased())
                .font(.system(size: 10, weight: .heavy))
                .tracking(0.8)
                .foregroundColor(Theme.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .frame(width: rowHeaderWidth, height: cellSize, alignment: .leading)
        .background(Theme.surfaceElevated)
    }

    private func dataRow(for rowField: CustomField) -> some View {
        HStack(spacing: 1) {
            rowHeaderCell(name: rowField.name)
            ForEach(plottableFields) { colField in
                cell(rowField: rowField, colField: colField)
            }
        }
    }

    @ViewBuilder
    private func cell(rowField: CustomField, colField: CustomField) -> some View {
        if rowField.name == colField.name {
            diagonalCell
        } else if let result = pairLookup[Self.pairKey(rowField.name, colField.name)] {
            Button {
                selectedPair = MatrixPairSelection(fieldA: rowField.name, fieldB: colField.name)
            } label: {
                valueCell(r: result.r)
            }
            .buttonStyle(.plain)
        } else {
            insufficientCell
        }
    }

    private var diagonalCell: some View {
        ZStack {
            Rectangle().fill(Theme.background)
            Text("—")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(Theme.textTertiary)
        }
        .frame(width: cellSize, height: cellSize)
    }

    private var insufficientCell: some View {
        ZStack {
            Rectangle().fill(Theme.background)
            Text("—")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(Theme.textTertiary.opacity(0.5))
        }
        .frame(width: cellSize, height: cellSize)
    }

    private func valueCell(r: Double) -> some View {
        ZStack {
            Rectangle().fill(CorrelationMatrixColor.color(for: r))
            Text(String(format: "%+.2f", r))
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(CorrelationMatrixColor.textColor(for: r))
        }
        .frame(width: cellSize, height: cellSize)
    }

    // MARK: - Legend

    private var legendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LEGEND")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.8)
                .foregroundColor(Theme.accent)

            VStack(spacing: 8) {
                legendRow(swatch: CorrelationMatrixColor.veryStrongPositive, label: "Very Strong Positive", range: "+0.7 to +1.0")
                legendRow(swatch: CorrelationMatrixColor.strongPositive, label: "Strong Positive", range: "+0.5 to +0.7")
                legendRow(swatch: CorrelationMatrixColor.moderatePositive, label: "Moderate Positive", range: "+0.3 to +0.5")
                legendRow(swatch: CorrelationMatrixColor.neutral, label: "Weak / No Correlation", range: "-0.3 to +0.3")
                legendRow(swatch: CorrelationMatrixColor.moderateNegative, label: "Moderate Negative", range: "-0.5 to -0.3")
                legendRow(swatch: CorrelationMatrixColor.strongNegative, label: "Strong Negative", range: "-0.7 to -0.5")
                legendRow(swatch: CorrelationMatrixColor.veryStrongNegative, label: "Very Strong Negative", range: "-1.0 to -0.7")
            }
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

    private func legendRow(swatch: Color, label: String, range: String) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(swatch)
                .frame(width: 28, height: 18)
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(Theme.hairline, lineWidth: 1)
                )
            Text(label)
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(Theme.textPrimary)
            Spacer(minLength: 0)
            Text(range)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.textTertiary)
        }
    }

    private var footerNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.textTertiary)
            Text("Cells showing a dash have fewer than \(BackgroundCorrelationScanner.minimumSessions) sessions with both values recorded. Tap a colored cell for full details.")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surface.opacity(0.6))
        )
    }

    private static func pairKey(_ a: String, _ b: String) -> String {
        a < b ? "\(a)||\(b)" : "\(b)||\(a)"
    }
}

// MARK: - Supporting types

private struct MatrixPairSelection: Identifiable {
    let fieldA: String
    let fieldB: String
    var id: String { "\(fieldA)||\(fieldB)" }
}

private enum CorrelationMatrixColor {
    static let veryStrongPositive = Theme.accent
    static let strongPositive = Theme.accent.opacity(0.65)
    static let moderatePositive = Theme.accent.opacity(0.35)
    static let neutral = Theme.surfaceElevated
    static let moderateNegative = Color(red: 0.35, green: 0.55, blue: 0.85).opacity(0.45)
    static let strongNegative = Color(red: 0.3, green: 0.55, blue: 0.9).opacity(0.75)
    static let veryStrongNegative = Color(red: 0.2, green: 0.55, blue: 0.95)

    static func color(for r: Double) -> Color {
        if r >= 0.7 { return veryStrongPositive }
        if r >= 0.5 { return strongPositive }
        if r >= 0.3 { return moderatePositive }
        if r > -0.3 { return neutral }
        if r > -0.5 { return moderateNegative }
        if r > -0.7 { return strongNegative }
        return veryStrongNegative
    }

    static func textColor(for r: Double) -> Color {
        if r >= 0.7 { return Theme.background }
        return Theme.textPrimary
    }
}

// MARK: - Pair detail view

private struct CorrelationPairDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let fieldAName: String
    let fieldBName: String
    let sessions: [Session]

    private var result: CorrelationResult {
        CorrelationEngine.calculate(sessions: sessions, fieldA: fieldAName, fieldB: fieldBName)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                mainContent
            }
            .navigationTitle("Correlation Detail")
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

    @ViewBuilder
    private var mainContent: some View {
        if result.sampleSize < CorrelationEngine.minimumSessions {
            insufficientData
        } else {
            ScrollView {
                VStack(spacing: 20) {
                    pairHeader
                    resultCard
                }
                .padding(20)
            }
        }
    }

    private var pairHeader: some View {
        HStack(spacing: 12) {
            Text(fieldAName.uppercased())
                .font(.system(size: 13, weight: .heavy))
                .tracking(1)
                .foregroundColor(Theme.accent)
                .lineLimit(1)
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.textTertiary)
            Text(fieldBName.uppercased())
                .font(.system(size: 13, weight: .heavy))
                .tracking(1)
                .foregroundColor(Theme.accent)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.accent.opacity(0.35), lineWidth: 1)
        )
    }

    private var insufficientData: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.7))
            Text("NOT ENOUGH DATA")
                .font(.system(size: 14, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.textPrimary)
            Text("At least \(CorrelationEngine.minimumSessions) sessions with both fields recorded are needed.")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            rValueSection
            Divider().background(Theme.hairline)
            HStack {
                strengthSection
                Spacer()
                confidenceBadge
            }
            Divider().background(Theme.hairline)
            insightSection
            sampleSection
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

    private var rValueSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PEARSON COEFFICIENT (r)")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Theme.textSecondary)
            Text(String(format: "%+.2f", result.r))
                .font(.system(size: 48, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.textPrimary)
        }
    }

    private var strengthSection: some View {
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

    private var confidenceBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: result.confidence.systemImage)
                .font(.system(size: 11, weight: .bold))
            Text(result.confidence.label.uppercased())
                .font(.system(size: 10, weight: .heavy))
                .tracking(1)
        }
        .foregroundColor(result.confidence.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(result.confidence.color.opacity(0.12)))
        .overlay(Capsule().stroke(result.confidence.color.opacity(0.4), lineWidth: 1))
    }

    private var insightSection: some View {
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

#Preview {
    CorrelationMatrixView()
        .modelContainer(for: [Session.self, CustomField.self, FieldValue.self, Track.self, Vehicle.self], inMemory: true)
}
