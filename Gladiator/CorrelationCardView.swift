//
//  CorrelationCardView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct CorrelationCardView: View {
    @Query(sort: [SortDescriptor(\CustomField.sortOrder)])
    private var allFields: [CustomField]
    @Query(sort: [SortDescriptor(\Session.date, order: .reverse)])
    private var sessions: [Session]

    @AppStorage("correlationFieldA") private var storedFieldA: String = ""
    @AppStorage("correlationFieldB") private var storedFieldB: String = ""

    @State private var showingFullView: Bool = false

    private var plottableFields: [CustomField] {
        allFields.filter { $0.fieldType.isPlottable }
    }

    private var hasFields: Bool {
        plottableFields.count >= 2
    }

    private var lastResult: CorrelationResult? {
        guard hasFields else { return nil }
        let a = resolvedFieldName(storedFieldA, fallbackIndex: 0)
        let b = resolvedFieldName(storedFieldB, fallbackIndex: 1)
        guard !a.isEmpty, !b.isEmpty, a != b else { return nil }
        return CorrelationEngine.calculate(sessions: sessions, fieldA: a, fieldB: b)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DATA ANALYSIS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Image(systemName: "function")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Theme.accent)
            }
            .padding(.horizontal, 4)

            Button { showingFullView = true } label: {
                cardBody
            }
            .buttonStyle(.plain)
        }
        .fullScreenCover(isPresented: $showingFullView) {
            CorrelationView()
        }
    }

    @ViewBuilder
    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !hasFields {
                emptyContent
            } else if let result = lastResult, result.sampleSize >= CorrelationEngine.minimumSessions {
                resultPreview(result)
            } else {
                promptContent
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private var emptyContent: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.textTertiary)
            Text("ADD 2+ NUMBER OR TIME METRICS")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }

    private var promptContent: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.7))
            Text("EXPLORE CORRELATIONS")
                .font(.system(size: 12, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(Theme.textPrimary)
            Text("Tap to analyze relationships between your metrics")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }

    private func resultPreview(_ result: CorrelationResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(result.fieldA.uppercased())
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.accent)
                Text("×")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
                Text(result.fieldB.uppercased())
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.accent)
            }

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(String(format: "%.2f", result.r))
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                Text(result.strength.label.uppercased())
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(result.strength.color)
            }

            Text("\(result.sampleSize) sessions analyzed")
                .font(.system(size: 10, weight: .bold))
                .tracking(1)
                .foregroundColor(Theme.textTertiary)
        }
    }

    private func resolvedFieldName(_ stored: String, fallbackIndex: Int) -> String {
        if !stored.isEmpty, plottableFields.contains(where: { $0.name == stored }) {
            return stored
        }
        guard plottableFields.count > fallbackIndex else { return "" }
        return plottableFields[fallbackIndex].name
    }
}

#Preview {
    CorrelationCardView()
        .padding(20)
        .background(Theme.background)
        .modelContainer(for: [Session.self, CustomField.self, FieldValue.self], inMemory: true)
        .preferredColorScheme(.dark)
}
