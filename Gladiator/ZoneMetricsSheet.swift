//
//  ZoneMetricsSheet.swift
//  Gladiator
//

import SwiftUI

private let zoneSheetCoordSpace = "zone-sheet"

private struct ZoneFieldFramesKey: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

struct ZoneMetricsSheet: View {
    let zone: CarZone
    let fields: [CustomField]
    @Binding var entries: [String: String]
    let onClose: () -> Void

    @FocusState private var focusedField: String?
    @State private var activeNumberField: String?
    @State private var fieldFrames: [String: CGRect] = [:]

    private var focusableNames: [String] {
        // Number fields use the custom bubble (not focused), and Time fields
        // use a wheel picker (also not focused). Only Text fields participate
        // in keyboard chevron navigation.
        fields.filter { $0.fieldType == .text }.map(\.name)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                    .dismissKeyboardOnTap()
                content

                if let activeName = activeNumberField,
                   let field = fields.first(where: { $0.name == activeName }),
                   let frame = fieldFrames[activeName] {
                    NumberPadBubbleOverlay(
                        anchorFrame: frame,
                        text: bindingForField(field),
                        onDismiss: { activeNumberField = nil }
                    )
                    .transition(.opacity)
                }
            }
            .coordinateSpace(name: zoneSheetCoordSpace)
            .onPreferenceChange(ZoneFieldFramesKey.self) { fieldFrames = $0 }
            .navigationTitle(zone.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .keyboardToolbar(focusedField: $focusedField, fields: focusableNames)
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var content: some View {
        if fields.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(fields.enumerated()), id: \.element.id) { index, field in
                        ZoneMetricRow(
                            field: field,
                            value: bindingForField(field),
                            focusedField: $focusedField,
                            isActiveNumberField: activeNumberField == field.name,
                            onTapNumberField: {
                                focusedField = nil
                                activeNumberField = field.name
                            }
                        )
                        if index < fields.count - 1 {
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
                .padding(20)
            }
            .scrollDisabled(activeNumberField != nil)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.textTertiary)
            Text("NO METRICS IN THIS ZONE")
                .font(.system(size: 12, weight: .heavy))
                .tracking(1.6)
                .foregroundColor(Theme.textSecondary)
            Text("Assign metrics to \(zone.displayName) in Settings → Session Customization → Metrics")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Done", action: onClose)
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(Theme.accent)
        }
    }

    private func bindingForField(_ field: CustomField) -> Binding<String> {
        Binding(
            get: { entries[field.name, default: ""] },
            set: { entries[field.name] = $0 }
        )
    }
}

private struct ZoneMetricRow: View {
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
                prompt: Text("Enter \(field.fieldType.rawValue.lowercased())")
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
                        key: ZoneFieldFramesKey.self,
                        value: [field.name: geo.frame(in: .named(zoneSheetCoordSpace))]
                    )
            }
        )
    }
}

#Preview {
    ZoneMetricsSheet(
        zone: .flTire,
        fields: [
            CustomField(name: "FL Pressure (PSI)", fieldType: .number, sortOrder: 0, zone: .flTire),
            CustomField(name: "FL Temp (F)", fieldType: .number, sortOrder: 1, zone: .flTire)
        ],
        entries: .constant([:]),
        onClose: {}
    )
}
