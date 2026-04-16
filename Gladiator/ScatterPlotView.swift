//
//  ScatterPlotView.swift
//  Gladiator
//

import SwiftUI
import SwiftData
import Charts

struct ScatterPlotView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\CustomField.sortOrder)])
    private var allFields: [CustomField]
    @Query(sort: [SortDescriptor(\Session.date, order: .reverse)])
    private var sessions: [Session]

    @AppStorage("scatterXField") private var storedXField: String = ""
    @AppStorage("scatterYField") private var storedYField: String = ""

    @State private var selectedPointID: UUID?
    @State private var showingXPicker: Bool = false
    @State private var showingYPicker: Bool = false
    @State private var navigateToSession: Session?

    private var numberFields: [CustomField] {
        allFields.filter { $0.fieldType == .number }
    }

    private var xFieldName: String {
        let name = storedXField
        if !name.isEmpty, numberFields.contains(where: { $0.name == name }) { return name }
        return numberFields.first?.name ?? ""
    }

    private var yFieldName: String {
        let name = storedYField
        if !name.isEmpty, numberFields.contains(where: { $0.name == name }) { return name }
        if numberFields.count >= 2 { return numberFields[1].name }
        return numberFields.first?.name ?? ""
    }

    private var points: [ScatterPoint] {
        buildPoints(sessions: sessions, xField: xFieldName, yField: yFieldName)
    }

    private var selectedPoint: ScatterPoint? {
        guard let id = selectedPointID else { return nil }
        return points.first { $0.id == id }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                mainContent
            }
            .navigationTitle("Scatter Plot")
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
            .navigationDestination(item: $navigateToSession) { session in
                SessionDetailView(session: session)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            axisSelectorBar
            Divider().background(Theme.hairline)
            chartArea
        }
    }

    // MARK: - Axis selectors

    private var axisSelectorBar: some View {
        HStack(spacing: 10) {
            axisButton(label: "X", fieldName: xFieldName) {
                showingXPicker = true
            }
            .sheet(isPresented: $showingXPicker) {
                fieldPicker(axis: "X", current: xFieldName) { name in
                    storedXField = name
                    selectedPointID = nil
                }
            }

            swapButton

            axisButton(label: "Y", fieldName: yFieldName) {
                showingYPicker = true
            }
            .sheet(isPresented: $showingYPicker) {
                fieldPicker(axis: "Y", current: yFieldName) { name in
                    storedYField = name
                    selectedPointID = nil
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private func axisButton(label: String, fieldName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(label)
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.background)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(Theme.accent))
                Text(fieldName.isEmpty ? "SELECT" : fieldName.uppercased())
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var swapButton: some View {
        Button {
            let oldX = storedXField.isEmpty ? xFieldName : storedXField
            let oldY = storedYField.isEmpty ? yFieldName : storedYField
            storedXField = oldY
            storedYField = oldX
            selectedPointID = nil
        } label: {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.accent)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Theme.accent.opacity(0.4), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Chart area

    @ViewBuilder
    private var chartArea: some View {
        if numberFields.isEmpty {
            emptyState(message: "ADD NUMBER FIELDS IN SETTINGS")
        } else if points.isEmpty {
            emptyState(message: "NO SESSIONS WITH DATA FOR BOTH FIELDS")
        } else {
            chartWithTooltipOverlay
        }
    }

    private func emptyState(message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "chart.dots.scatter")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.6))
            Text(message)
                .font(.system(size: 13, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Chart + tooltip overlay

    private var chartWithTooltipOverlay: some View {
        ZStack {
            VStack(spacing: 0) {
                chartWithAxisLabels
                    .padding(.top, 16)
                    .padding(.trailing, 20)
                    .padding(.bottom, 12)
            }

            if selectedPoint != nil {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { selectedPointID = nil }
                    .transition(.opacity)
            }

            if let point = selectedPoint {
                tooltipCard(for: point)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.2), value: selectedPointID)
    }

    // MARK: - Tooltip card

    private static let tooltipDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM dd, yyyy"
        return f
    }()

    private func tooltipCard(for point: ScatterPoint) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(point.sessionName)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                    Text(Self.tooltipDateFormatter.string(from: point.sessionDate))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                Button { selectedPointID = nil } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.accent)
                        .frame(width: 30, height: 30)
                        .background(Theme.accent.opacity(0.15))
                        .clipShape(Circle())
                }
            }

            Divider().background(Theme.hairline)

            HStack(spacing: 20) {
                tooltipStat(label: xFieldName, value: point.x)
                tooltipStat(label: yFieldName, value: point.y)
                Spacer()
            }

            Button {
                selectedPointID = nil
                navigateToSession = point.session
            } label: {
                HStack {
                    Spacer()
                    Text("VIEW SESSION")
                        .font(.system(size: 12, weight: .heavy))
                        .tracking(1.5)
                        .foregroundColor(Theme.background)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.background)
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.accent)
                )
                .shadow(color: Theme.accent.opacity(0.4), radius: 10)
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.accent.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: Theme.accent.opacity(0.2), radius: 20)
        .padding(.horizontal, 28)
    }

    private func tooltipStat(label: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(1.2)
                .foregroundColor(Theme.textSecondary)
            Text(formatValue(value))
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.accent)
        }
    }

    // MARK: - Chart with axis labels

    private var chartWithAxisLabels: some View {
        HStack(alignment: .center, spacing: 0) {
            yAxisLabel
            VStack(spacing: 6) {
                scatterChart
                    .frame(maxHeight: .infinity)
                xAxisLabel
            }
        }
    }

    private var yAxisLabel: some View {
        Text(yFieldName.uppercased())
            .font(.system(size: 10, weight: .heavy))
            .tracking(1.5)
            .foregroundColor(Theme.accent)
            .rotationEffect(.degrees(-90))
            .fixedSize()
            .frame(width: 28)
    }

    private var xAxisLabel: some View {
        Text(xFieldName.uppercased())
            .font(.system(size: 10, weight: .heavy))
            .tracking(1.5)
            .foregroundColor(Theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 4)
    }

    // MARK: - Scatter chart

    private var scatterChart: some View {
        Chart(points) { point in
            PointMark(
                x: .value(xFieldName, point.x),
                y: .value(yFieldName, point.y)
            )
            .foregroundStyle(selectedPointID == point.id ? Theme.accent : Theme.accent.opacity(0.7))
            .symbolSize(selectedPointID == point.id ? 120 : 60)
            .symbol(.circle)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine().foregroundStyle(Theme.hairline)
                AxisValueLabel()
                    .foregroundStyle(Theme.textTertiary)
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(Theme.hairline)
                AxisValueLabel()
                    .foregroundStyle(Theme.textTertiary)
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { tap in
                                handleTap(at: tap.location, proxy: proxy, geometry: geo)
                            }
                    )
            }
        }
        .animation(.easeOut(duration: 0.2), value: selectedPointID)
    }

    // MARK: - Tap handling

    private func handleTap(at location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        guard let plotFrame = proxy.plotFrame else {
            selectedPointID = nil
            return
        }
        let plotArea = geometry[plotFrame]
        let plotLocation = CGPoint(
            x: location.x - plotArea.origin.x,
            y: location.y - plotArea.origin.y
        )

        guard plotArea.contains(location),
              let _: Double = proxy.value(atX: plotLocation.x),
              let _: Double = proxy.value(atY: plotLocation.y) else {
            selectedPointID = nil
            return
        }

        let closest = points
            .map { point -> (ScatterPoint, Double) in
                let dist = screenDistance(point, tapLocation: location, plotArea: plotArea, proxy: proxy)
                return (point, dist)
            }
            .min { $0.1 < $1.1 }

        if let (point, dist) = closest, dist < 40 {
            selectedPointID = selectedPointID == point.id ? nil : point.id
        } else {
            selectedPointID = nil
        }
    }

    private func screenDistance(_ point: ScatterPoint, tapLocation: CGPoint,
                               plotArea: CGRect, proxy: ChartProxy) -> Double {
        guard let px = proxy.position(forX: point.x),
              let py = proxy.position(forY: point.y) else { return .infinity }
        let pointScreenX = plotArea.origin.x + px
        let pointScreenY = plotArea.origin.y + py
        let dx = pointScreenX - tapLocation.x
        let dy = pointScreenY - tapLocation.y
        return sqrt(dx * dx + dy * dy)
    }

    // MARK: - Field picker

    private func fieldPicker(axis: String, current: String, onSelect: @escaping (String) -> Void) -> some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(numberFields) { field in
                            FieldPickerRow(
                                name: field.name,
                                isSelected: field.name == current
                            ) {
                                onSelect(field.name)
                                if axis == "X" {
                                    showingXPicker = false
                                } else {
                                    showingYPicker = false
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("\(axis) Axis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if axis == "X" {
                            showingXPicker = false
                        } else {
                            showingYPicker = false
                        }
                    }
                    .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func formatValue(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }
}

private struct FieldPickerRow: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "number")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.accent)
                Text(name)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.accent)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Theme.accent.opacity(0.1) : Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Theme.accent.opacity(0.5) : Theme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ScatterPlotView()
        .modelContainer(for: [Session.self, CustomField.self, FieldValue.self], inMemory: true)
}
