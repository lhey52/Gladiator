//
//  CustomFieldsView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct CustomFieldsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\CustomField.sortOrder)])
    private var fields: [CustomField]

    @State private var showingAdd: Bool = false
    @State private var fieldToEdit: CustomField?
    @State private var fieldToDelete: CustomField?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            content
        }
        .navigationTitle("Session Metrics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.accent)
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddCustomFieldView(nextSortOrder: (fields.last?.sortOrder ?? -1) + 1)
        }
        .sheet(item: $fieldToEdit) { field in
            EditMetricView(field: field)
        }
        .alert(
            "Delete Metric",
            isPresented: Binding(
                get: { fieldToDelete != nil },
                set: { if !$0 { fieldToDelete = nil } }
            )
        ) {
            Button("Delete", role: .destructive) {
                if let field = fieldToDelete {
                    modelContext.delete(field)
                    fieldToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) { fieldToDelete = nil }
        } message: {
            if let field = fieldToDelete {
                Text("Are you sure you want to delete \"\(field.name)\"? This cannot be undone.")
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if fields.isEmpty {
            emptyState
        } else {
            fieldList
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "slider.horizontal.below.square.and.square.filled")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.8))
            Text("NO SESSION METRICS")
                .font(.system(size: 16, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.textPrimary)
            Text("Add metrics to track lap time, tire pressure, fuel load and more")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var fieldList: some View {
        List {
            ForEach(fields) { field in
                MetricRow(
                    field: field,
                    onEdit: { fieldToEdit = field },
                    onDelete: { fieldToDelete = field }
                )
                .listRowBackground(Theme.surface)
                .listRowSeparatorTint(Theme.hairline)
            }
            .onMove(perform: moveFields)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func moveFields(from source: IndexSet, to destination: Int) {
        var ordered = fields.map { $0 }
        ordered.move(fromOffsets: source, toOffset: destination)
        for (index, field) in ordered.enumerated() {
            field.sortOrder = index
        }
    }
}

private struct MetricRow: View {
    let field: CustomField
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Menu {
                Button { onEdit() } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive) { onDelete() } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(field.name)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(Theme.textPrimary)
                Text(field.fieldType.rawValue.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            Image(systemName: "line.3.horizontal")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        CustomFieldsView()
    }
    .modelContainer(for: [CustomField.self, FieldValue.self, Session.self], inMemory: true)
    .preferredColorScheme(.dark)
}
