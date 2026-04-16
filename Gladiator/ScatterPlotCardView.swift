//
//  ScatterPlotCardView.swift
//  Gladiator
//

import SwiftUI
import SwiftData
import Charts

struct ScatterPlotCardView: View {
    @Query(sort: [SortDescriptor(\CustomField.sortOrder)])
    private var allFields: [CustomField]
    @Query(sort: [SortDescriptor(\Session.date, order: .reverse)])
    private var sessions: [Session]

    @AppStorage("scatterXField") private var storedXField: String = ""
    @AppStorage("scatterYField") private var storedYField: String = ""

    @State private var showingFullScreen: Bool = false

    private var plottableFields: [CustomField] {
        allFields.filter { $0.fieldType.isPlottable }
    }

    private var xFieldName: String {
        let name = storedXField
        if !name.isEmpty, plottableFields.contains(where: { $0.name == name }) {
            return name
        }
        return plottableFields.first?.name ?? ""
    }

    private var yFieldName: String {
        let name = storedYField
        if !name.isEmpty, plottableFields.contains(where: { $0.name == name }) {
            return name
        }
        if plottableFields.count >= 2 {
            return plottableFields[1].name
        }
        return plottableFields.first?.name ?? ""
    }

    private var points: [ScatterPoint] {
        buildPoints(sessions: sessions, xField: xFieldName, yField: yFieldName)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("FIELD CORRELATION")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                if !plottableFields.isEmpty {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.accent)
                }
            }
            .padding(.horizontal, 4)

            Button {
                showingFullScreen = true
            } label: {
                cardBody
            }
            .buttonStyle(.plain)
            .disabled(plottableFields.isEmpty)
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
            ScatterPlotView()
        }
    }

    @ViewBuilder
    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            if plottableFields.isEmpty {
                emptyContent
            } else if points.isEmpty {
                needMoreDataContent
            } else {
                chartPreview
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
            Image(systemName: "chart.dots.scatter")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.textTertiary)
            Text("ADD NUMBER FIELDS TO PLOT")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
    }

    private var needMoreDataContent: some View {
        VStack(spacing: 8) {
            axisLabels
            Image(systemName: "chart.dots.scatter")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.textTertiary)
            Text("LOG MORE SESSIONS TO SEE DATA")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
    }

    private var chartPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            axisLabels
            previewChart
                .frame(height: 140)
        }
    }

    private var axisLabels: some View {
        HStack(spacing: 6) {
            Text(xFieldName.uppercased())
                .font(.system(size: 10, weight: .heavy))
                .tracking(1)
                .foregroundColor(Theme.accent)
            Text("VS")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Theme.textTertiary)
            Text(yFieldName.uppercased())
                .font(.system(size: 10, weight: .heavy))
                .tracking(1)
                .foregroundColor(Theme.accent)
        }
    }

    private var previewChart: some View {
        Chart(points) { point in
            PointMark(
                x: .value(xFieldName, point.x),
                y: .value(yFieldName, point.y)
            )
            .foregroundStyle(Theme.accent)
            .symbolSize(40)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine().foregroundStyle(Theme.hairline)
                AxisValueLabel()
                    .foregroundStyle(Theme.textTertiary)
                    .font(.system(size: 9, weight: .bold))
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(Theme.hairline)
                AxisValueLabel()
                    .foregroundStyle(Theme.textTertiary)
                    .font(.system(size: 9, weight: .bold))
            }
        }
    }
}

struct ScatterPoint: Identifiable {
    let id: UUID
    let session: Session
    let sessionName: String
    let sessionDate: Date
    let x: Double
    let y: Double
}

func buildPoints(sessions: [Session], xField: String, yField: String) -> [ScatterPoint] {
    guard !xField.isEmpty, !yField.isEmpty else { return [] }
    var result: [ScatterPoint] = []
    for session in sessions {
        let xVal = session.fieldValues.first(where: { $0.fieldName == xField })
        let yVal = session.fieldValues.first(where: { $0.fieldName == yField })
        guard let xStr = xVal?.value, let yStr = yVal?.value,
              let x = Double(xStr), let y = Double(yStr) else { continue }
        result.append(ScatterPoint(
            id: UUID(),
            session: session,
            sessionName: session.trackName.isEmpty ? "Untitled" : session.trackName,
            sessionDate: session.date,
            x: x,
            y: y
        ))
    }
    return result
}

#Preview {
    ScatterPlotCardView()
        .padding(20)
        .background(Theme.background)
        .modelContainer(for: [Session.self, CustomField.self, FieldValue.self], inMemory: true)
        .preferredColorScheme(.dark)
}
