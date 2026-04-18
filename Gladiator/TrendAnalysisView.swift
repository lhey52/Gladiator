//
//  TrendAnalysisView.swift
//  Gladiator
//

import SwiftUI
import SwiftData
import Charts

struct TrendAnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\CustomField.sortOrder)])
    private var allFields: [CustomField]
    @Query(sort: [SortDescriptor(\Session.date, order: .forward)])
    private var sessions: [Session]

    @AppStorage("trendFieldName") private var storedField: String = ""
    @State private var showingPicker: Bool = false
    @State private var windowSize: Int = 5

    private var plottableFields: [CustomField] {
        allFields.filter { $0.fieldType.isPlottable }
    }

    private var selectedFieldName: String {
        if !storedField.isEmpty, plottableFields.contains(where: { $0.name == storedField }) {
            return storedField
        }
        return plottableFields.first?.name ?? ""
    }

    private var selectedFieldType: FieldType {
        plottableFields.first(where: { $0.name == selectedFieldName })?.fieldType ?? .number
    }

    private var dataPoints: [TrendPoint] {
        var result: [TrendPoint] = []
        for (index, session) in sessions.enumerated() {
            guard let fv = session.fieldValues.first(where: { $0.fieldName == selectedFieldName }),
                  let val = Double(fv.value) else { continue }
            result.append(TrendPoint(
                id: "\(selectedFieldName)-\(index)",
                date: session.date,
                value: val
            ))
        }
        return result
    }

    private var movingAverage: [TrendPoint] {
        guard dataPoints.count >= windowSize else { return [] }
        var result: [TrendPoint] = []
        for i in (windowSize - 1)..<dataPoints.count {
            let window = dataPoints[(i - windowSize + 1)...i]
            let avg = window.map(\.value).reduce(0, +) / Double(windowSize)
            result.append(TrendPoint(
                id: "ma-\(i)",
                date: dataPoints[i].date,
                value: avg
            ))
        }
        return result
    }

    private var trendDirection: TrendDirection {
        guard movingAverage.count >= 2 else { return .stable }
        let recent = Array(movingAverage.suffix(3))
        guard recent.count >= 2 else { return .stable }
        let first = recent.first!.value
        let last = recent.last!.value
        let change = last - first
        let threshold = abs(first) * 0.02
        let isTime = selectedFieldType == .time
        if abs(change) < max(threshold, 0.01) { return .stable }
        if isTime {
            return change < 0 ? .improving : .declining
        }
        return change > 0 ? .improving : .declining
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                mainContent
            }
            .navigationTitle("Trend Analysis")
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

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                fieldSelector
                windowPicker
                trendIndicator
                chartSection
            }
            .padding(20)
        }
    }

    // MARK: - Field selector

    private var fieldSelector: some View {
        Button { showingPicker = true } label: {
            HStack(spacing: 10) {
                Text("METRIC")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.background)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Theme.accent))
                Text(selectedFieldName.isEmpty ? "SELECT METRIC" : selectedFieldName.uppercased())
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
        .sheet(isPresented: $showingPicker) {
            metricPicker
        }
    }

    // MARK: - Window picker

    private var windowPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MOVING AVERAGE WINDOW")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Theme.textSecondary)
                .padding(.leading, 4)

            HStack(spacing: 10) {
                ForEach([3, 5, 10], id: \.self) { size in
                    Button {
                        windowSize = size
                    } label: {
                        Text("\(size)")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(windowSize == size ? Theme.background : Theme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(windowSize == size ? Theme.accent : Theme.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(windowSize == size ? Theme.accent : Theme.hairline, lineWidth: 1)
                            )
                            .shadow(color: windowSize == size ? Theme.accent.opacity(0.35) : .clear, radius: 8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Trend indicator

    @ViewBuilder
    private var trendIndicator: some View {
        if dataPoints.count >= windowSize {
            HStack(spacing: 12) {
                Image(systemName: trendDirection.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(trendDirection.color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(trendDirection.label.uppercased())
                        .font(.system(size: 14, weight: .heavy))
                        .tracking(1.5)
                        .foregroundColor(trendDirection.color)
                    Text("\(dataPoints.count) sessions · \(windowSize)-session average")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(trendDirection.color.opacity(0.4), lineWidth: 1)
            )
        }
    }

    // MARK: - Chart

    @ViewBuilder
    private var chartSection: some View {
        if plottableFields.isEmpty {
            chartEmpty("ADD NUMBER OR TIME METRICS IN SETTINGS")
        } else if dataPoints.isEmpty {
            chartEmpty("NO DATA FOR THIS METRIC")
        } else {
            trendChart
        }
    }

    private func chartEmpty(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.6))
            Text(message)
                .font(.system(size: 12, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface)
        )
    }

    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedFieldName.uppercased())
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(Theme.accent)
                .padding(.leading, 4)

            Chart {
                ForEach(dataPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value(selectedFieldName, point.value)
                    )
                    .foregroundStyle(Theme.accent.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value(selectedFieldName, point.value)
                    )
                    .foregroundStyle(Theme.accent)
                    .symbolSize(30)
                }

                ForEach(movingAverage) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Average", point.value),
                        series: .value("Series", "MA")
                    )
                    .foregroundStyle(Theme.textPrimary)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, dash: [6, 4]))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { mark in
                    AxisGridLine().foregroundStyle(Theme.hairline)
                    AxisValueLabel {
                        if let val = mark.as(Double.self) {
                            Text(formatAxis(val))
                                .foregroundStyle(Theme.textTertiary)
                                .font(.system(size: 10, weight: .bold))
                        }
                    }
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
            .frame(height: 260)

            HStack(spacing: 16) {
                legendDot(color: Theme.accent, label: "Value")
                legendDot(color: Theme.textPrimary, label: "\(windowSize)-Session Avg", dashed: true)
            }
            .padding(.leading, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private func legendDot(color: Color, label: String, dashed: Bool = false) -> some View {
        HStack(spacing: 6) {
            if dashed {
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle().fill(color).frame(width: 4, height: 2)
                    }
                }
            } else {
                Circle().fill(color).frame(width: 8, height: 8)
            }
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Theme.textTertiary)
        }
    }

    private func formatAxis(_ value: Double) -> String {
        if selectedFieldType == .time {
            return TimeFormatting.secondsToAxisLabel(value)
        }
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    // MARK: - Metric picker

    private var metricPicker: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(plottableFields) { field in
                            Button {
                                storedField = field.name
                                showingPicker = false
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: field.fieldType.systemImage)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Theme.accent)
                                    Text(field.name)
                                        .font(.system(size: 15, weight: .heavy))
                                        .foregroundColor(Theme.textPrimary)
                                    Spacer()
                                    if field.name == selectedFieldName {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(Theme.accent)
                                    }
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(field.name == selectedFieldName ? Theme.accent.opacity(0.1) : Theme.surface)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(field.name == selectedFieldName ? Theme.accent.opacity(0.5) : Theme.hairline, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Select Metric")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingPicker = false }
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct TrendPoint: Identifiable {
    let id: String
    let date: Date
    let value: Double
}

enum TrendDirection {
    case improving
    case declining
    case stable

    var label: String {
        switch self {
        case .improving: return "Improving"
        case .declining: return "Declining"
        case .stable: return "Stable"
        }
    }

    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .declining: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    var color: Color {
        switch self {
        case .improving: return Theme.accent
        case .declining: return Color.red
        case .stable: return Theme.textSecondary
        }
    }
}

#Preview {
    TrendAnalysisView()
        .modelContainer(for: [Session.self, CustomField.self, FieldValue.self], inMemory: true)
}
