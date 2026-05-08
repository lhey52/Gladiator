//
//  SessionsView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct SessionsView: View {
    @Binding var externalTypeFilter: SessionType?

    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Session.date, order: .reverse)])
    private var sessions: [Session]
    @Query(sort: [SortDescriptor(\CustomField.sortOrder)])
    private var customFields: [CustomField]

    @State private var searchText: String = ""
    @State private var typeFilter: SessionType? = nil
    @State private var isEditing: Bool = false
    @State private var selectedIDs: Set<PersistentIdentifier> = []
    @State private var showingDeleteConfirm: Bool = false
    @State private var toastIcon: String = ""
    @State private var toastText: String = ""
    @State private var showToast: Bool = false
    @State private var showingPaywall: Bool = false
    @State private var showingFieldsPicker: Bool = false
    @State private var sortColumn: SessionsTableColumn = .date
    @State private var sortAscending: Bool = false
    @AppStorage("sessionsTableColumns") private var columnsJSON: String = ""
    @ObservedObject private var iap = IAPManager.shared
    @FocusState private var searchFocused: Bool

    // Unified ordered list of every column the picker knows about — both
    // the four built-in defaults and every CustomField the user has
    // defined. Rows are auto-merged with the live `customFields` query
    // so brand-new metrics appear at the bottom (disabled) and any stale
    // metric whose CustomField has been deleted is dropped.
    private var orderedEntries: [SessionsColumnEntry] {
        SessionsView.mergedEntries(
            stored: SessionsView.decodeEntries(from: columnsJSON),
            customFields: customFields
        )
    }

    // Subset of `orderedEntries` that's currently enabled, in display
    // order. This is what drives the table — `entry.enabled` toggling in
    // the picker shows/hides the column in the History table without the
    // row jumping to a different section in the picker.
    private var displayColumns: [SessionsTableColumn] {
        orderedEntries.compactMap { entry in
            entry.enabled ? SessionsTableColumn.from(id: entry.id) : nil
        }
    }

    static func decodeEntries(from json: String) -> [SessionsColumnEntry] {
        guard !json.isEmpty,
              let data = json.data(using: .utf8),
              let entries = try? JSONDecoder().decode([SessionsColumnEntry].self, from: data) else {
            return []
        }
        return entries
    }

    static func mergedEntries(
        stored: [SessionsColumnEntry],
        customFields: [CustomField]
    ) -> [SessionsColumnEntry] {
        let validMetricNames = Set(customFields.map(\.name))
        let valid = stored.filter { entry in
            guard let col = SessionsTableColumn.from(id: entry.id) else { return false }
            switch col {
            case .date, .type, .track, .vehicle: return true
            case .metric(let name): return validMetricNames.contains(name)
            }
        }
        let presentIDs = Set(valid.map(\.id))
        var merged = valid
        // Defaults the user hasn't seen yet → enabled, in default order
        for column in SessionsTableColumn.defaults where !presentIDs.contains(column.id) {
            merged.append(SessionsColumnEntry(id: column.id, enabled: true))
        }
        // Custom metrics added since last save → disabled, in CustomField sortOrder
        for field in customFields {
            let id = SessionsTableColumn.metric(field.name).id
            if !presentIDs.contains(id) {
                merged.append(SessionsColumnEntry(id: id, enabled: false))
            }
        }
        return merged
    }

    // Filter-then-sort. Search and type-filter behavior is unchanged from
    // before the table redesign — only the trailing sort step is new and
    // swaps direction whenever a column header is tapped.
    private var filteredSessions: [Session] {
        let filtered = sessions.filter { session in
            if let typeFilter, session.sessionType != typeFilter {
                return false
            }
            let trimmed = searchText.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { return true }
            return session.trackName.localizedCaseInsensitiveContains(trimmed)
                || session.sessionType.rawValue.localizedCaseInsensitiveContains(trimmed)
        }
        return filtered.sorted { lhs, rhs in
            let ascending: Bool
            switch sortColumn {
            case .date:
                ascending = lhs.date < rhs.date
            case .type:
                ascending = lhs.sessionType.rawValue
                    .localizedCaseInsensitiveCompare(rhs.sessionType.rawValue) == .orderedAscending
            case .track:
                ascending = lhs.trackName
                    .localizedCaseInsensitiveCompare(rhs.trackName) == .orderedAscending
            case .vehicle:
                ascending = lhs.vehicleName
                    .localizedCaseInsensitiveCompare(rhs.vehicleName) == .orderedAscending
            case .metric(let name):
                let lhsRaw = lhs.fieldValues.first { $0.fieldName == name }?.value ?? ""
                let rhsRaw = rhs.fieldValues.first { $0.fieldName == name }?.value ?? ""
                if let lhsDouble = Double(lhsRaw), let rhsDouble = Double(rhsRaw) {
                    ascending = lhsDouble < rhsDouble
                } else {
                    ascending = lhsRaw
                        .localizedCaseInsensitiveCompare(rhsRaw) == .orderedAscending
                }
            }
            return sortAscending ? ascending : !ascending
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                    .dismissKeyboardOnTap()

                VStack(spacing: 0) {
                    searchBar
                    filterBar
                    content
                    limitBanner
                }

                if showToast {
                    VStack {
                        Spacer()
                        ToastView(icon: toastIcon, text: toastText)
                            .transition(.opacity)
                            .padding(.bottom, 16)
                    }
                    .allowsHitTesting(false)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: showToast)
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Text("History")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        ProBadgeIfNeeded()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if isEditing {
                            isEditing = false
                            selectedIDs.removeAll()
                        } else {
                            isEditing = true
                        }
                    } label: {
                        Text(isEditing ? "Done" : "Edit")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(Theme.accent)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    if isEditing {
                        Button {
                            showingDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(selectedIDs.isEmpty ? Theme.textTertiary : Theme.accent)
                        }
                        .disabled(selectedIDs.isEmpty)
                    } else {
                        Button {
                            showingFieldsPicker = true
                        } label: {
                            Text("Fields")
                                .font(.system(size: 15, weight: .heavy))
                                .foregroundColor(Theme.accent)
                        }
                    }
                }
            }
            .confirmationDialog(
                "Delete \(selectedIDs.count) session\(selectedIDs.count == 1 ? "" : "s")?",
                isPresented: $showingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteSelected()
                }
                Button("Cancel", role: .cancel) { }
            }
            .onChange(of: externalTypeFilter) {
                if let filter = externalTypeFilter {
                    typeFilter = filter
                    externalTypeFilter = nil
                }
            }
            .onChange(of: sessions.count) { oldCount, newCount in
                if newCount < oldCount, !isEditing {
                    let deleted = oldCount - newCount
                    showToastBriefly(
                        icon: "trash",
                        text: deleted == 1 ? "Session Deleted" : "\(deleted) Sessions Deleted"
                    )
                }
            }
            .fullScreenCover(isPresented: $showingPaywall) {
                PaywallView(limitMessage: "You have reached the free limit of \(IAPManager.sessionLimit) sessions. Upgrade to Pro for unlimited sessions.")
            }
            .sheet(isPresented: $showingFieldsPicker) {
                SessionsFieldsPickerView(customFields: customFields)
            }
            .onChange(of: columnsJSON) { _, _ in
                // If the active sort column was just removed (toggled off
                // in the picker, or the underlying CustomField deleted),
                // fall back to Date / descending so the indicator never
                // sits on a hidden column.
                let visibleIDs = Set(displayColumns.map(\.id))
                if !visibleIDs.contains(sortColumn.id) {
                    sortColumn = .date
                    sortAscending = false
                }
            }
        }
    }

    @ViewBuilder
    private var limitBanner: some View {
        if iap.isAtSessionLimit(currentCount: sessions.count) {
            Button { showingPaywall = true } label: {
                HStack(spacing: 8) {
                    Text("You've reached the free limit. Upgrade to Pro for unlimited sessions.")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                    Text("Upgrade to Pro")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(Theme.accent)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Theme.surface)
                .overlay(
                    Rectangle().frame(height: 1).foregroundColor(Theme.hairline),
                    alignment: .top
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.textSecondary)
            TextField("", text: $searchText, prompt: Text("Search track or type").foregroundColor(Theme.textTertiary))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .focused($searchFocused)
                .submitLabel(.done)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.textTertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 12)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "ALL", isSelected: typeFilter == nil) {
                    typeFilter = nil
                }
                ForEach(SessionType.allCases) { type in
                    FilterChip(
                        title: type.shortLabel,
                        isSelected: typeFilter == type
                    ) {
                        typeFilter = (typeFilter == type) ? nil : type
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var content: some View {
        if filteredSessions.isEmpty {
            emptyState
        } else {
            ScrollView {
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 0) {
                        tableHeaderRow
                        ForEach(Array(filteredSessions.enumerated()), id: \.element.id) { index, session in
                            if isEditing {
                                Button {
                                    toggleSelection(session)
                                } label: {
                                    HStack(spacing: 0) {
                                        selectionCircle(for: session)
                                            .padding(.leading, 14)
                                            .padding(.trailing, 8)
                                        sessionTableRow(session)
                                    }
                                }
                                .buttonStyle(.plain)
                            } else {
                                NavigationLink {
                                    SessionDetailView(session: session)
                                } label: {
                                    sessionTableRow(session)
                                }
                                .buttonStyle(.plain)
                            }

                            if index < filteredSessions.count - 1 {
                                Divider().background(Theme.hairline)
                            }
                        }
                    }
                }
                .background(Theme.surface)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Table layout (matches MetricLogView styling)

    // Fixed column widths so the table can extend horizontally past the
    // screen when many metric columns are enabled. Header + rows share the
    // same widths and live inside the same horizontal ScrollView so they
    // scroll together.
    private static let dateColumnWidth: CGFloat = 80
    private static let typeColumnWidth: CGFloat = 60
    private static let trackColumnWidth: CGFloat = 110
    private static let vehicleColumnWidth: CGFloat = 110
    private static let metricColumnWidth: CGFloat = 110

    private var tableHeaderRow: some View {
        HStack(spacing: 0) {
            // In edit mode, leave room equal to the selection circle's
            // leading padding (14) + circle width (24) + trailing spacing (8)
            // so the header columns line up with the row columns below.
            if isEditing {
                Color.clear.frame(width: 46)
            }
            HStack(spacing: 8) {
                ForEach(displayColumns) { column in
                    headerCell(for: column)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Theme.surfaceElevated)
    }

    private func headerCell(for column: SessionsTableColumn) -> some View {
        Button {
            if sortColumn == column {
                sortAscending.toggle()
            } else {
                sortColumn = column
                // Date defaults to descending (newest first); other columns
                // default to ascending so A→Z reads naturally on first tap.
                sortAscending = (column != .date)
            }
        } label: {
            HStack(spacing: 4) {
                Text(Self.headerTitle(for: column).uppercased())
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.2)
                    .foregroundColor(sortColumn == column ? Theme.accent : Theme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if sortColumn == column {
                    Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(Theme.accent)
                }
            }
            .frame(width: Self.columnWidth(for: column), alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func sessionTableRow(_ session: Session) -> some View {
        HStack(spacing: 8) {
            ForEach(displayColumns) { column in
                cellText(for: column, session: session)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func cellText(for column: SessionsTableColumn, session: Session) -> some View {
        switch column {
        case .date:
            Text(Self.tableDateFormatter.string(from: session.date))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)
                .frame(width: Self.dateColumnWidth, alignment: .leading)
        case .type:
            Text(session.sessionType.shortLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)
                .frame(width: Self.typeColumnWidth, alignment: .leading)
        case .track:
            let isEmpty = session.trackName.isEmpty
            Text(isEmpty ? "—" : session.trackName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isEmpty ? Theme.textTertiary : Theme.textSecondary)
                .lineLimit(1)
                .frame(width: Self.trackColumnWidth, alignment: .leading)
        case .vehicle:
            let isEmpty = session.vehicleName.isEmpty
            Text(isEmpty ? "—" : session.vehicleName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isEmpty ? Theme.textTertiary : Theme.textSecondary)
                .lineLimit(1)
                .frame(width: Self.vehicleColumnWidth, alignment: .leading)
        case .metric(let name):
            let display = metricDisplayValue(forFieldName: name, in: session)
            let isMissing = (display == "—")
            Text(display)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isMissing ? Theme.textTertiary : Theme.textSecondary)
                .lineLimit(1)
                .frame(width: Self.metricColumnWidth, alignment: .leading)
        }
    }

    static func headerTitle(for column: SessionsTableColumn) -> String {
        switch column {
        case .date: return "Date"
        case .type: return "Type"
        case .track: return "Track"
        case .vehicle: return "Vehicle"
        case .metric(let name): return name
        }
    }

    static func columnWidth(for column: SessionsTableColumn) -> CGFloat {
        switch column {
        case .date: return dateColumnWidth
        case .type: return typeColumnWidth
        case .track: return trackColumnWidth
        case .vehicle: return vehicleColumnWidth
        case .metric: return metricColumnWidth
        }
    }

    private func metricDisplayValue(forFieldName name: String, in session: Session) -> String {
        let field = customFields.first { $0.name == name }
        guard let fv = session.fieldValues.first(where: { $0.fieldName == name }),
              !fv.value.trimmingCharacters(in: .whitespaces).isEmpty else {
            return "—"
        }
        if field?.fieldType == .time, let seconds = Double(fv.value), seconds > 0 {
            return TimeFormatting.secondsToDisplay(seconds)
        }
        return fv.value
    }

    private static let tableDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M/d/yy"
        return f
    }()

    private func selectionCircle(for session: Session) -> some View {
        let selected = selectedIDs.contains(session.persistentModelID)
        return ZStack {
            Circle()
                .stroke(selected ? Theme.accent : Theme.textTertiary, lineWidth: 2)
                .frame(width: 24, height: 24)
            if selected {
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 24, height: 24)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.background)
            }
        }
        .animation(.easeOut(duration: 0.15), value: selected)
    }

    private func toggleSelection(_ session: Session) {
        let id = session.persistentModelID
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    private func deleteSelected() {
        let count = selectedIDs.count
        for session in sessions where selectedIDs.contains(session.persistentModelID) {
            modelContext.delete(session)
        }
        selectedIDs.removeAll()
        isEditing = false
        showToastBriefly(
            icon: "trash",
            text: count == 1 ? "Session Deleted" : "\(count) Sessions Deleted"
        )
    }

    private func showToastBriefly(icon: String, text: String) {
        toastIcon = icon
        toastText = text
        showToast = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            showToast = false
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: sessions.isEmpty ? "flag.checkered" : "magnifyingglass")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.8))
            Text(sessions.isEmpty ? "NO SESSIONS YET" : "NO MATCHES")
                .font(.system(size: 16, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.textPrimary)
            Text(sessions.isEmpty ? "Log your first session in the New Session tab" : "Try a different search or filter")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// Single source of truth for both the History table's column layout and
// the sort selection — every renderable column maps to one of these cases,
// which means the picker's ordered list and the table's column order can
// share storage. Codable is used to persist the ordered list to AppStorage
// as a JSON-encoded array of `id` strings; Hashable + Identifiable let it
// drive ForEach + List `.onMove` directly.
enum SessionsTableColumn: Codable, Hashable, Identifiable {
    case date, type, track, vehicle
    case metric(String)

    var id: String {
        switch self {
        case .date: return "default:date"
        case .type: return "default:type"
        case .track: return "default:track"
        case .vehicle: return "default:vehicle"
        case .metric(let name): return "metric:\(name)"
        }
    }

    static func from(id: String) -> SessionsTableColumn? {
        switch id {
        case "default:date": return .date
        case "default:type": return .type
        case "default:track": return .track
        case "default:vehicle": return .vehicle
        default:
            if id.hasPrefix("metric:") {
                return .metric(String(id.dropFirst("metric:".count)))
            }
            return nil
        }
    }

    static let defaults: [SessionsTableColumn] = [.date, .type, .track, .vehicle]
}

// Stored per row in AppStorage so the picker can persist BOTH the
// vertical order and the on/off state of each column — that lets a
// disabled row sit at any position in the list without auto-shuffling
// to a separate "available" section when the user toggles it.
struct SessionsColumnEntry: Codable, Hashable, Identifiable {
    var id: String
    var enabled: Bool
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(isSelected ? Theme.background : Theme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Theme.accent : Theme.surface)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Theme.accent : Theme.hairline, lineWidth: 1)
                )
                .shadow(color: isSelected ? Theme.accent.opacity(0.4) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
    }
}

private struct SessionsFieldsPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let customFields: [CustomField]
    @AppStorage("sessionsTableColumns") private var columnsJSON: String = ""

    // Single ordered list of every known column — both defaults and
    // metrics — with each entry's enabled state. Defaults and metrics
    // share the same row format; only the toggle indicator differs based
    // on `enabled`. Reset clears storage and the view re-derives the
    // list with defaults enabled and metrics disabled.
    private var entries: [SessionsColumnEntry] {
        SessionsView.mergedEntries(
            stored: SessionsView.decodeEntries(from: columnsJSON),
            customFields: customFields
        )
    }

    private func saveEntries(_ entries: [SessionsColumnEntry]) {
        guard let data = try? JSONEncoder().encode(entries),
              let str = String(data: data, encoding: .utf8) else { return }
        columnsJSON = str
    }

    private func toggle(_ id: String) {
        var current = entries
        guard let idx = current.firstIndex(where: { $0.id == id }) else { return }
        current[idx].enabled.toggle()
        saveEntries(current)
    }

    private func reorder(from: IndexSet, to: Int) {
        var current = entries
        current.move(fromOffsets: from, toOffset: to)
        saveEntries(current)
    }

    private func resetToDefault() {
        // Empty string → next read of `entries` recomputes defaults
        // enabled and any custom fields disabled at their sortOrder
        // positions. No need to write anything explicit.
        columnsJSON = ""
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                content
            }
            .navigationTitle("Fields")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Theme.accent)
                }
            }
            .safeAreaInset(edge: .bottom) {
                resetButton
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Drag to reorder. Tap to add or remove columns from the History table.")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

            List {
                ForEach(entries) { entry in
                    rowButton(entry)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .deleteDisabled(true)
                }
                .onMove { from, to in
                    reorder(from: from, to: to)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.editMode, .constant(.active))
        }
    }

    private var resetButton: some View {
        Button {
            resetToDefault()
        } label: {
            Text("Reset to Default")
                .font(.system(size: 13, weight: .heavy))
                .tracking(1)
                .foregroundColor(Theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.surface)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Theme.hairline),
                    alignment: .top
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func rowButton(_ entry: SessionsColumnEntry) -> some View {
        if let column = SessionsTableColumn.from(id: entry.id) {
            Button {
                toggle(entry.id)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: iconName(for: column))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.accent)
                    Text(SessionsView.headerTitle(for: column))
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: entry.enabled ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(entry.enabled ? Theme.accent : Theme.textTertiary)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(entry.enabled ? Theme.accent.opacity(0.1) : Theme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(entry.enabled ? Theme.accent.opacity(0.5) : Theme.hairline, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func iconName(for column: SessionsTableColumn) -> String {
        switch column {
        case .date: return "calendar"
        case .type: return "flag.checkered"
        case .track: return "map"
        case .vehicle: return "car"
        case .metric(let name):
            return customFields.first { $0.name == name }?.fieldType.systemImage ?? "tablecells"
        }
    }
}

#Preview {
    SessionsView(externalTypeFilter: .constant(nil))
        .modelContainer(for: Session.self, inMemory: true)
        .preferredColorScheme(.dark)
}
