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
    @State private var date: Date = .now
    @State private var trackName: String = ""
    @State private var vehicleName: String = ""
    @State private var didLoadDefault: Bool = false
    @State private var sessionType: SessionType = .practice
    @State private var notes: String = ""
    @State private var fieldEntries: [String: String] = [:]
    @FocusState private var focusedField: SessionFormField?

    private var canSave: Bool {
        !trackName.isEmpty
    }

    private var allFields: [SessionFormField] {
        var result: [SessionFormField] = []
        for field in customFields {
            result.append(.custom(field.name))
        }
        result.append(.notes)
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                    .dismissKeyboardOnTap()
                formScroll
            }
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { navToolbar }
            .keyboardToolbar(focusedField: $focusedField, fields: allFields)
        }
        .preferredColorScheme(.dark)
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

    private var formScroll: some View {
        ScrollView {
            VStack(spacing: 18) {
                if !tipDismissed {
                    sessionFormTip
                }
                sessionCard
                if !customFields.isEmpty {
                    metricsCard
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
            Text("Customize your fields and metrics in Settings")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
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

    // MARK: - Session card (mirrors SessionDetailView header, but editable)

    private var sessionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            typeSelector
            trackField
            vehicleField
            dateField
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

    private var typeSelector: some View {
        HStack(spacing: 8) {
            ForEach(SessionType.allCases) { type in
                typeChip(type)
            }
            Spacer(minLength: 0)
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
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(isSelected ? Theme.accent.opacity(0.15) : Theme.surfaceElevated)
            )
            .overlay(
                Capsule().stroke(isSelected ? Theme.accent.opacity(0.5) : Theme.hairline, lineWidth: 1)
            )
            .fixedSize(horizontal: false, vertical: true)
        }
        .buttonStyle(.plain)
    }

    private var trackField: some View {
        Menu {
            ForEach(tracks) { track in
                Button(track.name) {
                    trackName = track.name
                }
            }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(trackName.isEmpty ? "Track Name" : trackName)
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundColor(trackName.isEmpty ? Theme.textTertiary : Theme.textPrimary)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var vehicleField: some View {
        Menu {
            Button("None") { vehicleName = "" }
            if !vehicles.isEmpty {
                Divider()
                ForEach(vehicles) { vehicle in
                    Button(vehicle.name) {
                        vehicleName = vehicle.name
                    }
                }
            }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(vehicleName.isEmpty ? "Vehicle" : vehicleName)
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundColor(vehicleName.isEmpty ? Theme.textTertiary : Theme.textPrimary)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var dateField: some View {
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

    // MARK: - Metrics card

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

    private var metricsCard: some View {
        VStack(spacing: 0) {
            cardHeader("CUSTOM DATA")
            ForEach(Array(customFields.enumerated()), id: \.element.id) { index, field in
                MetricRow(
                    field: field,
                    value: bindingForField(field),
                    focusedField: $focusedField
                )
                if index < customFields.count - 1 {
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

    var body: some View {
        HStack(alignment: .center) {
            Text(field.name.uppercased())
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(Theme.textSecondary)
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
