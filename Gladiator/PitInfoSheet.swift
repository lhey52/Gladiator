//
//  PitInfoSheet.swift
//  Gladiator
//

import SwiftUI

private let pitSheetCoordSpace = "pit-sheet"

private struct PitFieldFramesKey: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

/// Sheet presented when the driver taps the Pit Box affordance above the
/// race car diagram. Bundles the session-level fields (Track / Vehicle /
/// Date) with any metrics assigned to the General zone, mirroring the
/// per-zone sheets used elsewhere on the form.
struct PitInfoSheet: View {
    @Binding var date: Date
    @Binding var trackName: String
    @Binding var vehicleName: String
    @Binding var sessionType: SessionType
    let tracks: [Track]
    let vehicles: [Vehicle]
    let generalFields: [CustomField]
    @Binding var entries: [String: String]
    let onClose: () -> Void

    @FocusState private var focusedField: String?
    @State private var activeNumberField: String?
    @State private var fieldFrames: [String: CGRect] = [:]

    private var focusableNames: [String] {
        // Number fields use the bubble (not focused) and Time fields use a
        // wheel picker (also not focused). Only Text fields participate in
        // keyboard chevron navigation.
        generalFields.filter { $0.fieldType == .text }.map(\.name)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                    .dismissKeyboardOnTap()
                content

                if let activeName = activeNumberField,
                   let field = generalFields.first(where: { $0.name == activeName }),
                   let frame = fieldFrames[activeName] {
                    NumberPadBubbleOverlay(
                        anchorFrame: frame,
                        text: bindingForField(field),
                        onDismiss: { activeNumberField = nil }
                    )
                    .transition(.opacity)
                }
            }
            .coordinateSpace(name: pitSheetCoordSpace)
            .onPreferenceChange(PitFieldFramesKey.self) { fieldFrames = $0 }
            .navigationTitle("Pit Box")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .keyboardToolbar(focusedField: $focusedField, fields: focusableNames)
        }
        .preferredColorScheme(.dark)
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 18) {
                typeChips
                connectedList
            }
            .padding(20)
        }
        .scrollDisabled(activeNumberField != nil)
    }

    private var connectedList: some View {
        VStack(spacing: 0) {
            trackRow
            Divider().background(Theme.hairline)
            vehicleRow
            Divider().background(Theme.hairline)
            dateRow
            ForEach(generalFields) { field in
                Divider().background(Theme.hairline)
                PitMetricRow(
                    field: field,
                    value: bindingForField(field),
                    focusedField: $focusedField,
                    isActiveNumberField: activeNumberField == field.name,
                    onTapNumberField: {
                        focusedField = nil
                        activeNumberField = field.name
                    }
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

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Done", action: onClose)
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(Theme.accent)
        }
    }

    // MARK: - Track / Vehicle / Date rows

    private var trackRow: some View {
        infoRow(label: "TRACK") {
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
        infoRow(label: "VEHICLE") {
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
        infoRow(label: "DATE") {
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
    private func infoRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
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

    private func bindingForField(_ field: CustomField) -> Binding<String> {
        Binding(
            get: { entries[field.name, default: ""] },
            set: { entries[field.name] = $0 }
        )
    }
}

private struct PitMetricRow: View {
    let field: CustomField
    @Binding var value: String
    var focusedField: FocusState<String?>.Binding
    let isActiveNumberField: Bool
    let onTapNumberField: () -> Void

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
            input
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var input: some View {
        switch field.fieldType {
        case .time:
            TimePickerInput(totalSeconds: timeBinding)
        case .text:
            TextField(
                "",
                text: $value,
                prompt: Text("Enter text")
                    .foregroundColor(Theme.textTertiary)
            )
            .font(.system(size: 15, weight: .heavy))
            .foregroundColor(Theme.textPrimary)
            .keyboardType(.default)
            .multilineTextAlignment(.trailing)
            .autocorrectionDisabled()
            .focused(focusedField, equals: field.name)
        case .number:
            numberFieldButton
        }
    }

    private var numberFieldButton: some View {
        Button(action: onTapNumberField) {
            Text(value.isEmpty ? "Enter number" : value)
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(value.isEmpty ? Theme.textTertiary : Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(minWidth: 80, alignment: .trailing)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isActiveNumberField ? Theme.accent.opacity(0.15) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(
                            isActiveNumberField ? Theme.accent.opacity(0.6) : Theme.hairline,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(
                        key: PitFieldFramesKey.self,
                        value: [field.name: geo.frame(in: .named(pitSheetCoordSpace))]
                    )
            }
        )
    }
}

#Preview {
    PitInfoSheet(
        date: .constant(.now),
        trackName: .constant("Silverstone GP"),
        vehicleName: .constant("Spec Miata"),
        sessionType: .constant(.qualifying),
        tracks: [],
        vehicles: [],
        generalFields: [],
        entries: .constant([:]),
        onClose: {}
    )
}
