//
//  AddCustomFieldView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

private enum FieldFormField: Hashable {
    case name
    case unit
    case stepSize
}

struct AddCustomFieldView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\CustomField.sortOrder)])
    private var existingFields: [CustomField]

    let nextSortOrder: Int

    @State private var name: String = ""
    @State private var unit: String = ""
    @State private var stepSize: String = "0.0"
    @State private var fieldType: FieldType = .number
    @State private var pendingStepSize: Double = 0
    @State private var showZeroStepAlert: Bool = false
    @State private var showLargeStepAlert: Bool = false
    @FocusState private var focusedField: FieldFormField?

    private var isDuplicate: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return false }
        return existingFields.contains { $0.name.lowercased() == trimmed }
    }

    private var parsedStepSize: Double? {
        let trimmed = stepSize.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let value = Double(trimmed), value >= 0 else { return nil }
        return value
    }

    private var isStepSizeValid: Bool {
        // Only required when the metric is a Number type.
        fieldType != .number || parsedStepSize != nil
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !isDuplicate
            && isStepSizeValid
    }

    private var focusableFields: [FieldFormField] {
        fieldType == .number ? [.name, .unit, .stepSize] : [.name]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                    .dismissKeyboardOnTap()
                formContent
            }
            .navigationTitle("New Metric")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .keyboardToolbar(focusedField: $focusedField, fields: focusableFields)
            .alert("Warning", isPresented: $showZeroStepAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Confirm") { performSave() }
            } message: {
                Text("You have entered 0 for Step Size. This indicates you are not able to control this metric and may impact setup suggestions in Race Engineer. Are you sure?")
            }
            .alert("Note", isPresented: $showLargeStepAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Confirm") { performSave() }
            } message: {
                Text("Your Step Size is \(formatStepSize(pendingStepSize)). This is a larger than typical increment — please confirm this is correct.")
            }
        }
        .preferredColorScheme(.dark)
    }

    private var formContent: some View {
        ScrollView {
            VStack(spacing: 18) {
                nameCard
                if fieldType == .number {
                    unitCard
                    stepSizeCard
                }
                typeCard
            }
            .padding(20)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
                .foregroundColor(Theme.textSecondary)
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Add", action: attemptSave)
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(canSave ? Theme.accent : Theme.textTertiary)
                .disabled(!canSave)
        }
    }

    private var nameCard: some View {
        fieldCard(label: "METRIC NAME") {
            VStack(alignment: .leading, spacing: 8) {
                TextField(
                    "",
                    text: $name,
                    prompt: Text("e.g. Lap Time, Tire Pressure").foregroundColor(Theme.textTertiary)
                )
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(Theme.textPrimary)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .name)
                if isDuplicate {
                    Text("A metric with this name already exists")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
        }
    }

    private var unitCard: some View {
        fieldCard(label: "UNIT (OPTIONAL)") {
            TextField(
                "",
                text: $unit,
                prompt: Text("e.g. PSI, degrees F, lbs").foregroundColor(Theme.textTertiary)
            )
            .font(.system(size: 18, weight: .heavy))
            .foregroundColor(Theme.textPrimary)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($focusedField, equals: .unit)
        }
    }

    private var stepSizeCard: some View {
        fieldCard(label: "STEP SIZE") {
            VStack(alignment: .leading, spacing: 10) {
                Text("How precise can you be with adjustments? Enter 0 if this metric is outside your control (e.g. Outside Temperature)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 10) {
                    stepperButton(systemImage: "minus") { adjustStepSize(by: -0.1) }
                    TextField(
                        "",
                        text: $stepSize,
                        prompt: Text("0.0").foregroundColor(Theme.textTertiary)
                    )
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .stepSize)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.surfaceElevated)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Theme.hairline, lineWidth: 1)
                    )
                    stepperButton(systemImage: "plus") { adjustStepSize(by: 0.1) }
                }
            }
        }
    }

    private func stepperButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(Theme.accent)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.surfaceElevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Theme.accent.opacity(0.4), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func adjustStepSize(by delta: Double) {
        // Stepper buttons walk the parsed value by ±0.1 and clamp at zero.
        // Invalid text (mid-typing or non-numeric) is treated as zero so the
        // buttons stay responsive even if the user has cleared the field.
        let current = parsedStepSize ?? 0
        let next = max(0, current + delta)
        stepSize = formatStepSize(next)
    }

    private func formatStepSize(_ value: Double) -> String {
        // One decimal place per spec; using rounding to avoid floating-point
        // drift surfacing as e.g. "0.30000000000000004" after a few +0.1 taps.
        String(format: "%.1f", (value * 10).rounded() / 10)
    }

    private var typeCard: some View {
        fieldCard(label: "METRIC TYPE") {
            HStack(spacing: 10) {
                ForEach(FieldType.allCases) { type in
                    FieldTypeButton(type: type, isSelected: fieldType == type) {
                        fieldType = type
                    }
                }
            }
        }
    }

    private func attemptSave() {
        guard canSave else { return }
        // Step-size confirmations only apply to Number metrics. Text/Time
        // metrics skip straight to persistence.
        guard fieldType == .number, let value = parsedStepSize else {
            performSave()
            return
        }
        pendingStepSize = value
        if value == 0 {
            showZeroStepAlert = true
        } else if value > 10 {
            showLargeStepAlert = true
        } else {
            performSave()
        }
    }

    private func performSave() {
        let combinedName: String
        if fieldType == .number {
            combinedName = CustomField.combine(name: name, unit: unit)
        } else {
            combinedName = name.trimmingCharacters(in: .whitespaces)
        }
        let resolvedStepSize: Double? = fieldType == .number ? parsedStepSize : nil
        let field = CustomField(
            name: combinedName,
            fieldType: fieldType,
            sortOrder: nextSortOrder,
            stepSize: resolvedStepSize
        )
        modelContext.insert(field)
        dismiss()
    }

    @ViewBuilder
    private func fieldCard<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.8)
                .foregroundColor(Theme.accent)
            content()
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
}

private struct FieldTypeButton: View {
    let type: FieldType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: type.systemImage)
                    .font(.system(size: 18, weight: .bold))
                Text(type.rawValue.uppercased())
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1)
            }
            .foregroundColor(isSelected ? Theme.background : Theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Theme.accent : Theme.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Theme.accent : Theme.hairline, lineWidth: 1)
            )
            .shadow(color: isSelected ? Theme.accent.opacity(0.35) : .clear, radius: 10)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddCustomFieldView(nextSortOrder: 0)
        .modelContainer(for: [CustomField.self, FieldValue.self, Session.self], inMemory: true)
}
