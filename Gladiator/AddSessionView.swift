//
//  AddSessionView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

private enum SessionFormField: Hashable {
    case custom(String)
    case notes
}

struct AddSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\CustomField.sortOrder)])
    private var customFields: [CustomField]
    @Query(sort: [SortDescriptor(\Track.name)])
    private var tracks: [Track]
    @Query(sort: [SortDescriptor(\Vehicle.name)])
    private var vehicles: [Vehicle]

    @AppStorage("sessionFormTipDismissed") private var tipDismissed: Bool = false
    @AppStorage("sessionProgressBarEnabled") private var progressBarEnabled: Bool = true
    @State private var date: Date = .now
    @State private var trackName: String = ""
    @State private var vehicleName: String = ""
    @State private var didLoadDefault: Bool = false
    @State private var sessionType: SessionType = .practice
    @State private var notes: String = ""
    @State private var fieldEntries: [String: String] = [:]
    @State private var activeZone: CarZone?
    @FocusState private var focusedField: SessionFormField?

    private var canSave: Bool {
        !trackName.isEmpty
    }

    private var allFields: [SessionFormField] {
        var result: [SessionFormField] = []
        for field in customFields where field.fieldType != .time {
            result.append(.custom(field.name))
        }
        result.append(.notes)
        return result
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
            .navigationTitle("New Session")
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
        .onAppear {
            guard !didLoadDefault else { return }
            didLoadDefault = true
            if let defaultTrack = tracks.first(where: { $0.isDefault }) {
                trackName = defaultTrack.name
            }
            if let defaultVehicle = vehicles.first(where: { $0.isDefault }) {
                vehicleName = defaultVehicle.name
            }
        }
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
                typeChips
                sessionDetailsCard
                if !generalFields.isEmpty {
                    generalMetricsCard
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

    // MARK: - Session type chips

    private var typeChips: some View {
        HStack(spacing: 8) {
            ForEach(SessionType.allCases) { type in
                typeChip(type)
            }
        }
    }

    private func typeChip(_ type: SessionType) -> some View {
        let isSelected = sessionType == type
        return Button {
            sessionType = type
        } label: {
            HStack(spacing: 5) {
                Image(systemName: type.systemImage)
                    .font(.system(size: 11, weight: .bold))
                Text(type.rawValue.uppercased())
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .allowsTightening(true)
            }
            .foregroundColor(isSelected ? Theme.accent : Theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(isSelected ? Theme.accent.opacity(0.15) : Theme.surface)
            )
            .overlay(
                Capsule().stroke(isSelected ? Theme.accent.opacity(0.5) : Theme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Race car section

    private var raceCarSection: some View {
        VStack(spacing: 0) {
            cardHeader("ZONES")
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

    // MARK: - Session details card

    private var sessionDetailsCard: some View {
        VStack(spacing: 0) {
            cardHeader("SESSION")
            trackRow
            Divider().background(Theme.hairline)
            vehicleRow
            Divider().background(Theme.hairline)
            dateRow
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

    private var trackRow: some View {
        row(label: "TRACK") {
            Picker("", selection: $trackName) {
                Text("Select Track")
                    .foregroundColor(Theme.textTertiary)
                    .tag("")
                ForEach(tracks) { track in
                    Text(track.name).tag(track.name)
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.accent)
            .labelsHidden()
        }
    }

    private var vehicleRow: some View {
        row(label: "VEHICLE") {
            Picker("", selection: $vehicleName) {
                Text("Select Vehicle")
                    .foregroundColor(Theme.textTertiary)
                    .tag("")
                ForEach(vehicles) { vehicle in
                    Text(vehicle.name).tag(vehicle.name)
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.accent)
            .labelsHidden()
        }
    }

    private var dateRow: some View {
        row(label: "DATE") {
            DatePicker(
                "",
                selection: $date,
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .tint(Theme.accent)
            .colorScheme(.dark)
        }
    }

    @ViewBuilder
    private func row<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(Theme.textSecondary)
            Spacer()
            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - General metrics card

    private var generalMetricsCard: some View {
        VStack(spacing: 0) {
            cardHeader("GENERAL")
            ForEach(Array(generalFields.enumerated()), id: \.element.id) { index, field in
                MetricRow(
                    field: field,
                    value: bindingForField(field),
                    focusedField: $focusedField
                )
                if index < generalFields.count - 1 {
                    Divider().background(Theme.hairline)
                }
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

    private func save() {
        let session = Session(
            date: date,
            trackName: trackName.trimmingCharacters(in: .whitespaces),
            vehicleName: vehicleName.trimmingCharacters(in: .whitespaces),
            sessionType: sessionType,
            notes: notes
        )
        modelContext.insert(session)

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

private struct MetricRow: View {
    let field: CustomField
    @Binding var value: String
    var focusedField: FocusState<SessionFormField?>.Binding

    private var timeBinding: Binding<Double> {
        Binding(
            get: { Double(value) ?? 0 },
            set: { value = String($0) }
        )
    }

    private var parts: (name: String, unit: String) {
        CustomField.split(name: field.name)
    }

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(parts.name.uppercased())
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.5)
                    .foregroundColor(Theme.textSecondary)
                if !parts.unit.isEmpty {
                    Text(parts.unit)
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(0.8)
                        .foregroundColor(Theme.textTertiary)
                }
            }
            Spacer()
            if field.fieldType == .time {
                TimePickerInput(totalSeconds: timeBinding)
            } else {
                TextField(
                    "",
                    text: $value,
                    prompt: Text("Enter \(field.fieldType.rawValue.lowercased())")
                        .foregroundColor(Theme.textTertiary)
                )
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(Theme.textPrimary)
                .keyboardType(field.fieldType == .number ? .decimalPad : .default)
                .multilineTextAlignment(.trailing)
                .autocorrectionDisabled()
                .focused(focusedField, equals: .custom(field.name))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    AddSessionView()
        .modelContainer(for: [CustomField.self, FieldValue.self, Session.self], inMemory: true)
}
