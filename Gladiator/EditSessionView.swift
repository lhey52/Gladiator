//
//  EditSessionView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

private enum EditSessionField: Hashable {
    case notes
}

struct EditSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\CustomField.sortOrder)])
    private var customFields: [CustomField]
    @Query(sort: [SortDescriptor(\Track.name)])
    private var tracks: [Track]
    @Query(sort: [SortDescriptor(\Vehicle.name)])
    private var vehicles: [Vehicle]

    let session: Session

    @AppStorage("sessionFormTipDismissed") private var tipDismissed: Bool = false
    @AppStorage("sessionProgressBarEnabled") private var progressBarEnabled: Bool = true
    @State private var date: Date = .now
    @State private var trackName: String = ""
    @State private var vehicleName: String = ""
    @State private var sessionType: SessionType = .practice
    @State private var notes: String = ""
    @State private var fieldEntries: [String: String] = [:]
    @State private var activeZone: CarZone?
    @State private var pitSheetPresented: Bool = false
    @FocusState private var focusedField: EditSessionField?

    private var canSave: Bool {
        !trackName.isEmpty
    }

    private var allFields: [EditSessionField] {
        // Only the inline notes editor is focusable on the form root —
        // metric inputs live inside the zone and pit-box sheets and have
        // their own focus state.
        [.notes]
    }

    private var generalFields: [CustomField] {
        customFields.filter { $0.zone == .general }
    }

    private var zoneStates: [CarZone: ZoneFillState] {
        var result: [CarZone: ZoneFillState] = [:]
        for zone in CarZone.carZones {
            let zoneFields = customFields.filter { $0.zone == zone }
            let filled = zoneFields.reduce(0) { count, field in
                count + (isFieldFilled(field) ? 1 : 0)
            }
            result[zone] = ZoneFillState(filled: filled, total: zoneFields.count)
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                    .dismissKeyboardOnTap()
                VStack(spacing: 0) {
                    if progressBarEnabled {
                        progressBar
                    }
                    formScroll
                }
            }
            .navigationTitle("Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { navToolbar }
            .keyboardToolbar(focusedField: $focusedField, fields: allFields)
        }
        .preferredColorScheme(.dark)
        .sheet(item: $activeZone) { zone in
            ZoneMetricsSheet(
                zone: zone,
                fields: customFields.filter { $0.zone == zone },
                entries: $fieldEntries,
                onClose: { activeZone = nil }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $pitSheetPresented) {
            PitInfoSheet(
                date: $date,
                trackName: $trackName,
                vehicleName: $vehicleName,
                sessionType: $sessionType,
                tracks: tracks,
                vehicles: vehicles,
                generalFields: generalFields,
                entries: $fieldEntries,
                onClose: { pitSheetPresented = false }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear { loadSession() }
    }

    private func isFieldFilled(_ field: CustomField) -> Bool {
        let raw = fieldEntries[field.name, default: ""].trimmingCharacters(in: .whitespaces)
        if raw.isEmpty { return false }
        if field.fieldType == .time, let val = Double(raw), val == 0 { return false }
        return true
    }

    private var completionProgress: Double {
        let total = 3 + customFields.count
        guard total > 0 else { return 0 }
        var filled = 1 // session type always has a value
        if !trackName.trimmingCharacters(in: .whitespaces).isEmpty { filled += 1 }
        if !vehicleName.trimmingCharacters(in: .whitespaces).isEmpty { filled += 1 }
        for field in customFields where isFieldFilled(field) {
            filled += 1
        }
        return Double(filled) / Double(total)
    }

    private var progressBar: some View {
        VStack(alignment: .trailing, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.surfaceElevated)
                        .frame(height: 5)
                    Capsule()
                        .fill(Theme.accent)
                        .frame(width: max(geo.size.width * completionProgress, completionProgress > 0 ? 4 : 0), height: 5)
                        .shadow(color: Theme.accent.opacity(0.4), radius: 4)
                }
            }
            .frame(height: 5)

            Text("\(Int((completionProgress * 100).rounded()))% COMPLETE")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.2)
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .animation(.easeInOut(duration: 0.25), value: completionProgress)
    }

    private var formScroll: some View {
        ScrollView {
            VStack(spacing: 18) {
                raceCarSection
                if !tipDismissed {
                    sessionFormTip
                }
                notesCard
            }
            .padding(20)
        }
    }

    private var sessionFormTip: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.accent)
            Text("Tap any zone on the car to enter its metrics. Customize fields in Settings.")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button { tipDismissed = true } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
                    .frame(width: 24, height: 24)
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
                .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Theme.accent.opacity(0.12), radius: 10, y: 4)
    }

    @ToolbarContentBuilder
    private var navToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
                .foregroundColor(Theme.textSecondary)
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save", action: save)
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(canSave ? Theme.accent : Theme.textTertiary)
                .disabled(!canSave)
        }
    }

    // MARK: - Race car section

    private var raceCarSection: some View {
        VStack(spacing: 0) {
            cardHeader("ZONES")
            pitBoxElement
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            RaceCarDiagramView(
                zoneStates: zoneStates,
                onTapZone: { zone in
                    focusedField = nil
                    activeZone = zone
                }
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 14)
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

    private var pitBoxElement: some View {
        Button {
            focusedField = nil
            pitSheetPresented = true
        } label: {
            VStack(spacing: 2) {
                Text("PIT BOX")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.8)
                    .foregroundColor(Theme.accent)
                Text("TRACK · VEHICLE · GENERAL")
                    .font(.system(size: 8, weight: .heavy))
                    .tracking(1.2)
                    .foregroundColor(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Theme.accent.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Theme.accent.opacity(0.50), lineWidth: 1.5)
            )
            .shadow(color: Theme.accent.opacity(0.20), radius: 6)
        }
        .buttonStyle(.plain)
    }

    private func cardHeader(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.8)
                .foregroundColor(Theme.accent)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    // MARK: - Notes card

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NOTES")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.8)
                .foregroundColor(Theme.accent)

            ZStack(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("Setup, conditions, thoughts…")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.textTertiary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $notes)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .focused($focusedField, equals: .notes)
            }
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

    private func bindingForField(_ field: CustomField) -> Binding<String> {
        Binding(
            get: { fieldEntries[field.name, default: ""] },
            set: { fieldEntries[field.name] = $0 }
        )
    }

    private func loadSession() {
        date = session.date
        trackName = session.trackName
        vehicleName = session.vehicleName
        sessionType = session.sessionType
        notes = session.notes
        for fv in session.fieldValues {
            fieldEntries[fv.fieldName] = fv.value
        }
    }

    private func save() {
        session.date = date
        session.trackName = trackName.trimmingCharacters(in: .whitespaces)
        session.vehicleName = vehicleName.trimmingCharacters(in: .whitespaces)
        session.sessionType = sessionType
        session.notes = notes

        for fv in session.fieldValues {
            modelContext.delete(fv)
        }

        for field in customFields {
            let raw = fieldEntries[field.name, default: ""].trimmingCharacters(in: .whitespaces)
            if raw.isEmpty { continue }
            if field.fieldType == .time, let val = Double(raw), val == 0 { continue }
            let fv = FieldValue(fieldName: field.name, fieldType: field.fieldType, value: raw, session: session)
            modelContext.insert(fv)
        }

        dismiss()
    }
}

#Preview {
    EditSessionView(
        session: Session(
            date: .now,
            trackName: "Silverstone GP",
            sessionType: .qualifying,
            notes: "Soft compound, track temp 28°C."
        )
    )
    .modelContainer(for: [CustomField.self, FieldValue.self, Session.self], inMemory: true)
}
