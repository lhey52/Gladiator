//
//  ZoneMetricsSheet.swift
//  Gladiator
//

import SwiftUI

struct ZoneMetricsSheet: View {
    let zone: CarZone
    let fields: [CustomField]
    @Binding var entries: [String: String]
    let onClose: () -> Void

    @FocusState private var focusedField: String?

    private var focusableNames: [String] {
        fields.filter { $0.fieldType != .time }.map(\.name)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                    .dismissKeyboardOnTap()
                content
            }
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
                            focusedField: $focusedField
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
                .focused(focusedField, equals: field.name)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
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
