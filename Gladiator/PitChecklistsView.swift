//
//  PitChecklistsView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct PitChecklistsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\PitChecklistTemplate.sortOrder)])
    private var templates: [PitChecklistTemplate]

    @State private var selectedTemplate: PitChecklistTemplate?
    @State private var templateToEdit: PitChecklistTemplate?
    @State private var newTemplate: PitChecklistTemplate?
    @State private var templateToDelete: PitChecklistTemplate?
    @State private var showToast: Bool = false
    @State private var toastText: String = ""

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            content

            if showToast {
                VStack {
                    Spacer()
                    ToastView(icon: "checkmark.circle.fill", text: toastText)
                        .transition(.opacity)
                        .padding(.bottom, 16)
                }
                .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showToast)
        .navigationTitle("Checklists")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { createTemplate() } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.accent)
                }
            }
        }
        .navigationDestination(item: $selectedTemplate) { template in
            PitChecklistDetailView(template: template)
        }
        .navigationDestination(item: $templateToEdit) { template in
            PitChecklistEditView(template: template)
        }
        .navigationDestination(item: $newTemplate) { template in
            PitChecklistEditView(template: template, isNew: true) {
                showToastBriefly("Checklist Created")
            }
        }
        .alert(
            "Delete Checklist",
            isPresented: Binding(
                get: { templateToDelete != nil },
                set: { if !$0 { templateToDelete = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) { templateToDelete = nil }
            Button("Delete", role: .destructive) {
                if let template = templateToDelete {
                    modelContext.delete(template)
                    templateToDelete = nil
                }
            }
        } message: {
            if let template = templateToDelete {
                Text("Delete \"\(template.name.isEmpty ? "this checklist" : template.name)\"?")
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if templates.isEmpty {
            emptyState
        } else {
            list
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "checklist")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.8))
            Text("NO CHECKLISTS")
                .font(.system(size: 16, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.textPrimary)
            Text("Build reusable checklists for Pre-Race, Setup Check, Post-Race and more")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(templates.enumerated()), id: \.element.id) { index, template in
                    row(template)
                    if index < templates.count - 1 {
                        Divider().background(Theme.hairline).padding(.leading, 14)
                    }
                }
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(20)
        }
    }

    private func row(_ template: PitChecklistTemplate) -> some View {
        HStack(spacing: 12) {
            Button {
                selectedTemplate = template
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name.isEmpty ? "Untitled checklist" : template.name)
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(Theme.textPrimary)
                            .lineLimit(1)
                        Text(progressLabel(for: template))
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.8)
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Menu {
                Button {
                    templateToEdit = template
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    templateToDelete = template
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func progressLabel(for template: PitChecklistTemplate) -> String {
        let total = template.items.count
        if total == 0 {
            return "NO ITEMS YET"
        }
        return "\(template.checkedCount) OF \(total) COMPLETE"
    }

    private func createTemplate() {
        let nextOrder = (templates.last?.sortOrder ?? -1) + 1
        let template = PitChecklistTemplate(name: "", sortOrder: nextOrder)
        modelContext.insert(template)
        newTemplate = template
    }

    private func showToastBriefly(_ text: String) {
        toastText = text
        showToast = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            showToast = false
        }
    }
}

#Preview {
    NavigationStack {
        PitChecklistsView()
    }
    .modelContainer(for: [PitChecklistTemplate.self, PitChecklistItem.self], inMemory: true)
    .preferredColorScheme(.dark)
}
