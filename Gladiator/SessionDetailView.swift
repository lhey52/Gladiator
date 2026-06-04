//
//  SessionDetailView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\CustomField.sortOrder)])
    private var customFields: [CustomField]

    let session: Session

    @State private var showingDeleteConfirm: Bool = false
    @State private var showingEdit: Bool = false
    @State private var showSavedToast: Bool = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    headerCard
                    ForEach(groupedFieldValues, id: \.zone) { group in
                        zoneCard(zone: group.zone, values: group.values)
                    }
                    if !session.notes.trimmingCharacters(in: .whitespaces).isEmpty {
                        notesCard
                    }
                }
                .padding(20)
            }

            if showSavedToast {
                VStack {
                    Spacer()
                    ToastView(icon: "checkmark.circle.fill", text: "Session Saved")
                        .transition(.opacity)
                        .padding(.bottom, 16)
                }
                .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showSavedToast)
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 16) {
                    Button { showingEdit = true } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Theme.accent)
                    }
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Theme.accent)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditSessionView(session: session) {
                showSavedToast = true
                Task {
                    try? await Task.sleep(for: .seconds(2))
                    showSavedToast = false
                }
            }
        }
        .confirmationDialog(
            "Delete this session?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: deleteSession)
            Button("Cancel", role: .cancel) { }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(session.sessionType.rawValue.uppercased(), systemImage: session.sessionType.systemImage)
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.5)
                    .foregroundColor(Theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.accent.opacity(0.15))
                    .overlay(Capsule().stroke(Theme.accent.opacity(0.5), lineWidth: 1))
                    .clipShape(Capsule())
                Spacer()
            }
            Text(session.trackName.isEmpty ? "Untitled Track" : session.trackName)
                .font(.system(size: 32, weight: .heavy))
                .foregroundColor(Theme.textPrimary)
            if !session.vehicleName.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text(session.vehicleName)
                        .font(.system(size: 14, weight: .heavy))
                }
                .foregroundColor(Theme.textSecondary)
            }
            Text(Self.dateFormatter.string(from: session.date))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.accent.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: Theme.accent.opacity(0.15), radius: 16)
    }

    private var metaCard: some View {
        VStack(spacing: 0) {
            detailRow(label: "TRACK", value: session.trackName.isEmpty ? "—" : session.trackName)
            Divider().background(Theme.hairline)
            detailRow(label: "TYPE", value: session.sessionType.rawValue)
            Divider().background(Theme.hairline)
            detailRow(label: "DATE", value: Self.dateFormatter.string(from: session.date))
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
        )
    }

    private var sortedFieldValues: [FieldValue] {
        session.fieldValues.sorted { $0.fieldName.localizedCompare($1.fieldName) == .orderedAscending }
    }

    // Order the zone sections are shown in. General leads (rendered as
    // "PIT DATA"), then the four corners, chassis, and engine. A zone only
    // gets a card if the session actually has values assigned to it.
    private static let zoneDisplayOrder: [CarZone] = [
        .general, .flTire, .frTire, .blTire, .brTire, .chassis, .engine
    ]

    // Resolve a stored value's zone via its CustomField. Values whose metric
    // was since deleted fall back to the zone encoded in the name prefix, and
    // anything unrecognized lands in General / Pit Data.
    private func zone(forFieldName name: String) -> CarZone {
        if let field = customFields.first(where: { $0.name == name }) {
            return field.zone
        }
        for zone in CarZone.carZones where !zone.metricNamePrefix.isEmpty && name.hasPrefix(zone.metricNamePrefix) {
            return zone
        }
        return .general
    }

    private var groupedFieldValues: [(zone: CarZone, values: [FieldValue])] {
        let grouped = Dictionary(grouping: sortedFieldValues) { zone(forFieldName: $0.fieldName) }
        return Self.zoneDisplayOrder.compactMap { zone in
            guard let values = grouped[zone], !values.isEmpty else { return nil }
            return (zone, values)
        }
    }

    private func zoneTitle(for zone: CarZone) -> String {
        zone == .general ? "PIT DATA" : zone.displayName.uppercased()
    }

    private func zoneCard(zone: CarZone, values: [FieldValue]) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(zoneTitle(for: zone))
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.8)
                    .foregroundColor(Theme.accent)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            ForEach(Array(values.enumerated()), id: \.element.id) { index, fv in
                if index > 0 {
                    Divider().background(Theme.hairline)
                }
                detailRow(
                    label: CustomField.stripPrefix(from: fv.fieldName, zone: zone).uppercased(),
                    value: displayValue(for: fv)
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NOTES")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.8)
                .foregroundColor(Theme.accent)
            Text(session.notes)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func displayValue(for fv: FieldValue) -> String {
        if fv.fieldType == .time, let secs = Double(fv.value) {
            return TimeFormatting.secondsToDisplay(secs)
        }
        return fv.value
    }

    private func deleteSession() {
        modelContext.delete(session)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        SessionDetailView(
            session: Session(
                date: .now,
                trackName: "Silverstone GP",
                sessionType: .qualifying,
                notes: "Soft compound, track temp 28°C. Rear felt loose on T3."
            )
        )
    }
    .modelContainer(for: Session.self, inMemory: true)
    .preferredColorScheme(.dark)
}
