//
//  PitChecklistEditView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

private enum ChecklistEditField: Hashable {
    case name
    case item(PersistentIdentifier)
}

struct PitChecklistEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let template: PitChecklistTemplate
    var isNew: Bool = false
    var onCreated: (() -> Void)? = nil

    @State private var name: String = ""
    @State private var newItemText: String = ""
    @State private var didLoad: Bool = false
    @FocusState private var focusedField: ChecklistEditField?

    private var orderedItems: [PitChecklistItem] { template.sortedItems }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
                .dismissKeyboardOnTap()

            ScrollView {
                VStack(spacing: 18) {
                    nameCard
                    itemsCard
                    addItemCard
                }
                .padding(20)
            }
        }
        .navigationTitle(isNew ? "New Checklist" : "Edit Checklist")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Done", action: save)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(canSave ? Theme.accent : Theme.textTertiary)
                    .disabled(!canSave)
            }
        }
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            name = template.name
        }
        .onDisappear { commit(removeIfEmpty: isNew) }
    }

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CHECKLIST NAME")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.8)
                .foregroundColor(Theme.accent)
            TextField(
                "",
                text: $name,
                prompt: Text("e.g. Pre-Race").foregroundColor(Theme.textTertiary)
            )
            .font(.system(size: 18, weight: .heavy))
            .foregroundColor(Theme.textPrimary)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .focused($focusedField, equals: .name)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private var itemsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ITEMS")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.8)
                .foregroundColor(Theme.accent)

            if orderedItems.isEmpty {
                Text("No items yet — add some below.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textTertiary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(orderedItems.enumerated()), id: \.element.id) { index, item in
                        itemRow(item)
                        if index < orderedItems.count - 1 {
                            Divider().background(Theme.hairline)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surfaceElevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.hairline, lineWidth: 1)
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private func itemRow(_ item: PitChecklistItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Theme.textTertiary)
            TextField(
                "",
                text: Binding(
                    get: { item.text },
                    set: { item.text = $0 }
                ),
                prompt: Text("Item").foregroundColor(Theme.textTertiary)
            )
            .font(.system(size: 14, weight: .heavy))
            .foregroundColor(Theme.textPrimary)
            .focused($focusedField, equals: .item(item.persistentModelID))

            Button {
                delete(item)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var addItemCard: some View {
        HStack(spacing: 10) {
            TextField(
                "",
                text: $newItemText,
                prompt: Text("Add an item").foregroundColor(Theme.textTertiary)
            )
            .font(.system(size: 15, weight: .heavy))
            .foregroundColor(Theme.textPrimary)
            .submitLabel(.done)
            .onSubmit { addItem() }

            Button {
                addItem()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(newItemText.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.textTertiary : Theme.accent)
            }
            .buttonStyle(.plain)
            .disabled(newItemText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.accent.opacity(0.4), lineWidth: 1)
        )
    }

    private func addItem() {
        let trimmed = newItemText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let nextOrder = (template.items.map(\.sortOrder).max() ?? -1) + 1
        let item = PitChecklistItem(text: trimmed, sortOrder: nextOrder)
        item.template = template
        modelContext.insert(item)
        newItemText = ""
    }

    private func delete(_ item: PitChecklistItem) {
        modelContext.delete(item)
    }

    private func save() {
        guard canSave else { return }
        commit(removeIfEmpty: false)
        if isNew { onCreated?() }
        dismiss()
    }

    private func commit(removeIfEmpty: Bool) {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if removeIfEmpty && trimmedName.isEmpty {
            modelContext.delete(template)
            return
        }
        template.name = trimmedName
        for item in template.items {
            let trimmed = item.text.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                modelContext.delete(item)
            } else {
                item.text = trimmed
            }
        }
    }
}

#Preview {
    NavigationStack {
        PitChecklistEditView(template: PitChecklistTemplate(name: "Pre-Race"))
    }
    .modelContainer(for: [PitChecklistTemplate.self, PitChecklistItem.self], inMemory: true)
    .preferredColorScheme(.dark)
}
