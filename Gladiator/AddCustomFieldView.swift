//
//  AddCustomFieldView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

private enum FieldFormField: Hashable {
    case name
}

struct AddCustomFieldView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let nextSortOrder: Int

    @State private var name: String = ""
    @State private var fieldType: FieldType = .number
    @FocusState private var focusedField: FieldFormField?

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
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
            .keyboardToolbar(focusedField: $focusedField, fields: [.name])
        }
        .preferredColorScheme(.dark)
    }

    private var formContent: some View {
        ScrollView {
            VStack(spacing: 18) {
                nameCard
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
            Button("Add", action: save)
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(canSave ? Theme.accent : Theme.textTertiary)
                .disabled(!canSave)
        }
    }

    private var nameCard: some View {
        fieldCard(label: "METRIC NAME") {
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
        let field = CustomField(
            name: name.trimmingCharacters(in: .whitespaces),
            fieldType: fieldType,
            sortOrder: nextSortOrder
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
