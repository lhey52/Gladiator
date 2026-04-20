//
//  EditSessionView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

private enum EditSessionField: Hashable {
    case track
    case custom(String)
    case notes
}

struct EditSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\CustomField.sortOrder)])
    private var customFields: [CustomField]
    @Query(sort: [SortDescriptor(\Track.name)])
    private var tracks: [Track]

    let session: Session

    @AppStorage("sessionFormTipDismissed") private var tipDismissed: Bool = false
    @State private var date: Date = .now
    @State private var trackName: String = ""
    @State private var sessionType: SessionType = .practice
    @State private var notes: String = ""
    @State private var fieldEntries: [String: String] = [:]
    @FocusState private var focusedField: EditSessionField?

    private var canSave: Bool {
        !trackName.isEmpty
    }

    private var allFields: [EditSessionField] {
        var result: [EditSessionField] = []
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
            .navigationTitle("Edit Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { navToolbar }
            .keyboardToolbar(focusedField: $focusedField, fields: allFields)
        }
        .preferredColorScheme(.dark)
        .onAppear { loadSession() }
    }

    private var formScroll: some View {
        ScrollView {
            VStack(spacing: 18) {
                if !tipDismissed {
                    sessionFormTip
                }
                trackCard
                dateCard
                typeCard
                customFieldCards
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

    private var trackCard: some View {
        fieldCard(label: "TRACK") {
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
            .font(.system(size: 18, weight: .heavy))
        }
    }

    private var dateCard: some View {
        fieldCard(label: "DATE") {
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

    private var typeCard: some View {
        fieldCard(label: "SESSION TYPE") {
            HStack(spacing: 8) {
                ForEach(SessionType.allCases) { type in
                    TypeButton(
                        type: type,
                        isSelected: sessionType == type
                    ) {
                        sessionType = type
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var customFieldCards: some View {
        ForEach(customFields) { field in
            CustomFieldInput(
                field: field,
                value: bindingForField(field),
                focusedField: $focusedField
            )
        }
    }

    private var notesCard: some View {
        fieldCard(label: "NOTES", alignment: .leading) {
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
        sessionType = session.sessionType
        notes = session.notes
        for fv in session.fieldValues {
            fieldEntries[fv.fieldName] = fv.value
        }
    }

    private func save() {
        session.date = date
        session.trackName = trackName.trimmingCharacters(in: .whitespaces)
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

    @ViewBuilder
    private func fieldCard<Content: View>(
        label: String,
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: alignment, spacing: 10) {
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

private struct CustomFieldInput: View {
    let field: CustomField
    @Binding var value: String
    var focusedField: FocusState<EditSessionField?>.Binding

    private var timeBinding: Binding<Double> {
        Binding(
            get: { Double(value) ?? 0 },
            set: { value = String($0) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: field.fieldType.systemImage)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.accent)
                Text(field.name.uppercased())
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.8)
                    .foregroundColor(Theme.accent)
            }
            if field.fieldType == .time {
                TimePickerInput(totalSeconds: timeBinding)
            } else {
                TextField(
                    "",
                    text: $value,
                    prompt: Text("Enter \(field.fieldType.rawValue.lowercased())").foregroundColor(Theme.textTertiary)
                )
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(Theme.textPrimary)
                .keyboardType(field.fieldType == .number ? .decimalPad : .default)
                .autocorrectionDisabled()
                .focused(focusedField, equals: .custom(field.name))
                .frame(maxWidth: .infinity, alignment: .leading)
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
}

private struct TypeButton: View {
    let type: SessionType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: type.systemImage)
                    .font(.system(size: 16, weight: .bold))
                Text(type.shortLabel)
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1)
            }
            .foregroundColor(isSelected ? Theme.background : Theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
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
