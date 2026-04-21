//
//  PitChecklistDetailView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct PitChecklistDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let template: PitChecklistTemplate

    @State private var templateToEdit: PitChecklistTemplate?

    private var items: [PitChecklistItem] { template.sortedItems }
    private var total: Int { items.count }
    private var checked: Int { template.checkedCount }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            content
        }
        .navigationTitle(template.name.isEmpty ? "Checklist" : template.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    templateToEdit = template
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.accent)
                }
            }
        }
        .navigationDestination(item: $templateToEdit) { template in
            PitChecklistEditView(template: template)
        }
    }

    @ViewBuilder
    private var content: some View {
        if items.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    progressCard
                    resetButton
                    itemList
                }
                .padding(20)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "checklist")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.8))
            Text("EMPTY CHECKLIST")
                .font(.system(size: 16, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.textPrimary)
            Text("Tap the pencil to add items to this checklist")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("PROGRESS")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.8)
                    .foregroundColor(Theme.accent)
                Spacer()
                Text("\(checked) of \(total) complete")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundColor(Theme.textPrimary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Theme.surfaceElevated)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Theme.accent)
                        .frame(width: max(progressWidth(total: total, width: geo.size.width), total > 0 && checked > 0 ? 4 : 0), height: 8)
                        .shadow(color: Theme.accent.opacity(0.4), radius: 4)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.accent.opacity(0.35), lineWidth: 1)
        )
    }

    private func progressWidth(total: Int, width: CGFloat) -> CGFloat {
        guard total > 0 else { return 0 }
        return width * CGFloat(checked) / CGFloat(total)
    }

    private var resetButton: some View {
        Button(action: resetAll) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 13, weight: .heavy))
                Text("RESET CHECKLIST")
                    .font(.system(size: 13, weight: .heavy))
                    .tracking(1.5)
            }
            .foregroundColor(checked > 0 ? Theme.background : Theme.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(checked > 0 ? Theme.accent : Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(checked > 0 ? Theme.accent : Theme.hairline, lineWidth: 1)
            )
            .shadow(color: checked > 0 ? Theme.accent.opacity(0.4) : .clear, radius: 10)
        }
        .buttonStyle(.plain)
        .disabled(checked == 0)
    }

    private var itemList: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                Button { toggle(item) } label: {
                    itemRow(item)
                }
                .buttonStyle(.plain)
                if index < items.count - 1 {
                    Divider().background(Theme.hairline).padding(.leading, 50)
                }
            }
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func itemRow(_ item: PitChecklistItem) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(item.isChecked ? Theme.accent : Theme.textTertiary, lineWidth: 2)
                    .frame(width: 24, height: 24)
                if item.isChecked {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 24, height: 24)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(Theme.background)
                }
            }

            Text(item.text.isEmpty ? "Untitled" : item.text)
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(item.isChecked ? Theme.accent : Theme.textPrimary)
                .strikethrough(item.isChecked, color: Theme.accent)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .animation(.easeOut(duration: 0.15), value: item.isChecked)
    }

    private func toggle(_ item: PitChecklistItem) {
        item.isChecked.toggle()
    }

    private func resetAll() {
        for item in template.items where item.isChecked {
            item.isChecked = false
        }
    }
}

#Preview {
    NavigationStack {
        PitChecklistDetailView(template: PitChecklistTemplate(name: "Pre-Race"))
    }
    .modelContainer(for: [PitChecklistTemplate.self, PitChecklistItem.self], inMemory: true)
    .preferredColorScheme(.dark)
}
