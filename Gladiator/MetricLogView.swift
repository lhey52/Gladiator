//
//  MetricLogView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct MetricLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\CustomField.sortOrder)])
    private var allFields: [CustomField]
    @Query(sort: [SortDescriptor(\Session.date, order: .reverse)])
    private var sessions: [Session]

    @AppStorage("metricLogField") private var storedField: String = ""

    @State private var filter = AnalyticsFilterState()
    @State private var showingFilter: Bool = false
    @State private var showingPicker: Bool = false
    @State private var sortField: SortField = .date
    @State private var sortOrder: SortOrder = .descending
    @State private var isLoading: Bool = true

    private enum SortField: Equatable {
        case date
        case value
    }

    private enum SortOrder: Equatable {
        case ascending
        case descending
    }

    private struct LogEntry: Identifiable {
        let id: PersistentIdentifier
        let session: Session
        let date: Date
        let trackName: String
        let vehicleName: String
        let value: Double
    }

    private var plottableFields: [CustomField] {
        allFields.filter { $0.fieldType.isPlottable }
    }

    private var selectedField: CustomField? {
        plottableFields.first { $0.name == storedField }
    }

    private var filteredSessions: [Session] {
        filter.apply(to: sessions)
    }

    private var entries: [LogEntry] {
        guard let field = selectedField else { return [] }
        let fieldName = field.name
        var result: [LogEntry] = []
        for session in filteredSessions {
            guard let fv = session.fieldValues.first(where: { $0.fieldName == fieldName }),
                  let value = Double(fv.value) else { continue }
            result.append(LogEntry(
                id: session.persistentModelID,
                session: session,
                date: session.date,
                trackName: session.trackName,
                vehicleName: session.vehicleName,
                value: value
            ))
        }
        return sort(result)
    }

    private func sort(_ list: [LogEntry]) -> [LogEntry] {
        switch sortField {
        case .date:
            return list.sorted {
                sortOrder == .descending ? $0.date > $1.date : $0.date < $1.date
            }
        case .value:
            return list.sorted {
                sortOrder == .descending ? $0.value > $1.value : $0.value < $1.value
            }
        }
    }

    var body: some View {
        if isLoading {
            AnalyticsLoadingView(
                toolName: "Metric Log",
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
            .navigationTitle("Metric Log")
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
            .sheet(isPresented: $showingPicker) {
                pickerSheet
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Main content

    @ViewBuilder
    private var mainContent: some View {
        if plottableFields.isEmpty {
            emptyState(
                icon: "tablecells",
                headline: "ADD METRICS",
                message: "Add Number or Time metrics in Settings to use the Metric Log."
            )
        } else {
            ScrollView {
                VStack(spacing: 18) {
                    ToolDescriptionCard(text: "View every session that has a recorded value for a chosen metric. Pick a metric from the selector, then tap the Date or Value column headers to toggle sort direction. Tap any row to open that session.")
                    fieldSelector
                    tableContent
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

    private func inlineEmptyState(icon: String, headline: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.6))
            Text(headline)
                .font(.system(size: 13, weight: .heavy))
                .tracking(1.8)
                .foregroundColor(Theme.textPrimary)
            Text(message)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
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
                Text(selectedField?.name.uppercased() ?? "SELECT METRIC")
                    .font(.system(size: 14, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(selectedField == nil ? Theme.textTertiary : Theme.textPrimary)
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

    // MARK: - Table

    @ViewBuilder
    private var tableContent: some View {
        if selectedField == nil {
            inlineEmptyState(
                icon: "hand.tap",
                headline: "SELECT A METRIC",
                message: "Choose a metric above to view every recorded value."
            )
        } else if entries.isEmpty {
            inlineEmptyState(
                icon: "tablecells",
                headline: "NO RECORDED VALUES",
                message: "No sessions match the current filters for this metric."
            )
        } else {
            tableCard
        }
    }

    private var tableCard: some View {
        VStack(spacing: 0) {
            tableHeader
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                NavigationLink {
                    SessionDetailView(session: entry.session)
                } label: {
                    tableRow(entry)
                }
                .buttonStyle(.plain)
                if index < entries.count - 1 {
                    Divider().background(Theme.hairline)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var tableHeader: some View {
        HStack(spacing: 8) {
            sortableHeader(label: "DATE", field: .date)
                .frame(maxWidth: .infinity, alignment: .leading)
            staticHeader("TRACK")
                .frame(maxWidth: .infinity, alignment: .leading)
            staticHeader("VEHICLE")
                .frame(maxWidth: .infinity, alignment: .leading)
            sortableHeader(label: "VALUE", field: .value)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.surfaceElevated)
    }

    private func sortableHeader(label: String, field: SortField) -> some View {
        Button {
            toggleSort(for: field)
        } label: {
            HStack(spacing: 4) {
                if field == .value { Spacer(minLength: 0) }
                Text(label)
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.2)
                    .foregroundColor(sortField == field ? Theme.accent : Theme.textSecondary)
                if sortField == field {
                    Image(systemName: sortOrder == .descending ? "arrow.down" : "arrow.up")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(Theme.accent)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func staticHeader(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .heavy))
            .tracking(1.2)
            .foregroundColor(Theme.textSecondary)
    }

    private func toggleSort(for field: SortField) {
        if sortField == field {
            sortOrder = sortOrder == .descending ? .ascending : .descending
        } else {
            sortField = field
            sortOrder = .descending
        }
    }

    // MARK: - Row

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM dd, yyyy"
        return f
    }()

    private func tableRow(_ entry: LogEntry) -> some View {
        HStack(spacing: 8) {
            Text(Self.dateFormatter.string(from: entry.date))
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(entry.trackName.isEmpty ? "—" : entry.trackName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(entry.vehicleName.isEmpty ? "—" : entry.vehicleName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(formatValue(entry.value))
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func formatValue(_ value: Double) -> String {
        guard let field = selectedField else { return String(format: "%.2f", value) }
        if field.fieldType == .time {
            return TimeFormatting.secondsToDisplay(value)
        }
        if value == value.rounded() {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }

    // MARK: - Picker sheet

    private var pickerSheet: some View {
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
                                    if field.name == storedField {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(Theme.accent)
                                    }
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(field.name == storedField ? Theme.accent.opacity(0.1) : Theme.surface)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(field.name == storedField ? Theme.accent.opacity(0.5) : Theme.hairline, lineWidth: 1)
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

#Preview {
    MetricLogView()
        .modelContainer(for: [Session.self, CustomField.self, FieldValue.self, Track.self, Vehicle.self], inMemory: true)
}
