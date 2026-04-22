//
//  EditMetricView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

private enum EditFormField: Hashable {
    case name
    case unit
}

struct EditMetricView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\CustomField.sortOrder)])
    private var existingFields: [CustomField]

    let field: CustomField

    @State private var name: String = ""
    @State private var unit: String = ""
    @State private var fieldType: FieldType = .number
    @FocusState private var focusedField: EditFormField?

    private var isDuplicate: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return false }
        return existingFields.contains { $0.name.lowercased() == trimmed && $0.persistentModelID != field.persistentModelID }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !isDuplicate
    }

    private var focusableFields: [EditFormField] {
        fieldType == .number ? [.name, .unit] : [.name]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                    .dismissKeyboardOnTap()
                formContent
            }
            .navigationTitle("Edit Metric")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .keyboardToolbar(focusedField: $focusedField, fields: focusableFields)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            let parts = CustomField.split(name: field.name)
            name = parts.name
            unit = parts.unit
            fieldType = field.fieldType
        }
    }

    private var formContent: some View {
        ScrollView {
            VStack(spacing: 18) {
                nameCard
                if fieldType == .number {
                    unitCard
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
            Button("Save", action: save)
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

    private func save() {
        if fieldType == .number {
            field.name = CustomField.combine(name: name, unit: unit)
        } else {
            field.name = name.trimmingCharacters(in: .whitespaces)
        }
        field.fieldType = fieldType
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
    EditMetricView(field: CustomField(name: "Lap Time", fieldType: .number, sortOrder: 0))
        .modelContainer(for: [CustomField.self, FieldValue.self, Session.self], inMemory: true)
}
