//
//  PitGoalsView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct PitGoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\PitGoal.createdAt, order: .reverse)])
    private var goals: [PitGoal]

    @State private var goalToEdit: PitGoal?
    @State private var goalToDelete: PitGoal?
    @State private var showingNewGoal: Bool = false

    private var groupedGoals: [(status: GoalStatus, goals: [PitGoal])] {
        GoalStatus.allCases
            .sorted { $0.sortIndex < $1.sortIndex }
            .map { status in
                (status, goals.filter { $0.status == status })
            }
            .filter { !$0.goals.isEmpty }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            content
        }
        .navigationTitle("Goals")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingNewGoal = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.accent)
                }
            }
        }
        .sheet(isPresented: $showingNewGoal) {
            GoalEditorSheet(mode: .create) { draft in
                let goal = PitGoal(
                    title: draft.title,
                    details: draft.details,
                    targetValue: draft.targetValue,
                    targetDate: draft.targetDate,
                    status: draft.status
                )
                modelContext.insert(goal)
            }
        }
        .sheet(item: $goalToEdit) { goal in
            GoalEditorSheet(mode: .edit(goal)) { draft in
                goal.title = draft.title
                goal.details = draft.details
                goal.targetValue = draft.targetValue
                goal.targetDate = draft.targetDate
                goal.status = draft.status
            }
        }
        .alert(
            "Delete Goal",
            isPresented: Binding(
                get: { goalToDelete != nil },
                set: { if !$0 { goalToDelete = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) { goalToDelete = nil }
            Button("Delete", role: .destructive) {
                if let goal = goalToDelete {
                    modelContext.delete(goal)
                    goalToDelete = nil
                }
            }
        } message: {
            Text("This goal will be permanently deleted.")
        }
    }

    @ViewBuilder
    private var content: some View {
        if goals.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(groupedGoals, id: \.status) { group in
                        section(for: group.status, goals: group.goals)
                    }
                }
                .padding(20)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "flag.2.crossed.fill")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.8))
            Text("NO GOALS YET")
                .font(.system(size: 16, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.textPrimary)
            Text("Set racing targets — lap times, championship results, anything measurable")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func section(for status: GoalStatus, goals: [PitGoal]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: status.systemImage)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundColor(status.color)
                Text(status.rawValue.uppercased())
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.8)
                    .foregroundColor(status.color)
                Text("(\(goals.count))")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
                Spacer()
            }
            .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(goals.enumerated()), id: \.element.id) { index, goal in
                    Button { goalToEdit = goal } label: {
                        goalRow(goal)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        if goal.status != .achieved {
                            Button {
                                goal.status = .achieved
                            } label: {
                                Label("Achieve", systemImage: "checkmark.seal.fill")
                            }
                            .tint(Theme.accent)
                        }
                        Button(role: .destructive) {
                            goalToDelete = goal
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    if index < goals.count - 1 {
                        Divider().background(Theme.hairline).padding(.leading, 14)
                    }
                }
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func goalRow(_ goal: PitGoal) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title.isEmpty ? "Untitled goal" : goal.title)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                if !goal.targetValue.isEmpty {
                    Text("TARGET: \(goal.targetValue.uppercased())")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundColor(Theme.accent)
                        .lineLimit(1)
                }
                if let date = goal.targetDate {
                    Text("BY \(Self.dateFormatter.string(from: date).uppercased())")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.8)
                        .foregroundColor(Theme.textSecondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(14)
        .contentShape(Rectangle())
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM dd, yyyy"
        return f
    }()
}

// MARK: - Editor sheet

private struct GoalDraft {
    var title: String
    var details: String
    var targetValue: String
    var targetDate: Date?
    var status: GoalStatus
}

private enum GoalEditorMode {
    case create
    case edit(PitGoal)

    var isCreate: Bool {
        if case .create = self { return true }
        return false
    }
}

private struct GoalEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let mode: GoalEditorMode
    let onSave: (GoalDraft) -> Void

    @State private var title: String = ""
    @State private var details: String = ""
    @State private var targetValue: String = ""
    @State private var status: GoalStatus = .notStarted
    @State private var hasTargetDate: Bool = false
    @State private var targetDate: Date = .now.addingTimeInterval(60 * 60 * 24 * 30)
    @State private var didLoad: Bool = false

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                    .dismissKeyboardOnTap()

                ScrollView {
                    VStack(spacing: 18) {
                        titleCard
                        targetCard
                        dateCard
                        statusCard
                        detailsCard
                    }
                    .padding(20)
                }
            }
            .navigationTitle(mode.isCreate ? "New Goal" : "Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
        }
        .preferredColorScheme(.dark)
        .onAppear { loadIfNeeded() }
    }

    private var titleCard: some View {
        field(label: "TITLE") {
            TextField(
                "",
                text: $title,
                prompt: Text("e.g. Sub 1:30 lap at Silverstone").foregroundColor(Theme.textTertiary)
            )
            .font(.system(size: 18, weight: .heavy))
            .foregroundColor(Theme.textPrimary)
            .textInputAutocapitalization(.sentences)
            .autocorrectionDisabled()
        }
    }

    private var targetCard: some View {
        field(label: "TARGET VALUE") {
            TextField(
                "",
                text: $targetValue,
                prompt: Text("e.g. 1:29.5, P3, 50 points").foregroundColor(Theme.textTertiary)
            )
            .font(.system(size: 18, weight: .heavy))
            .foregroundColor(Theme.textPrimary)
            .autocorrectionDisabled()
        }
    }

    private var dateCard: some View {
        field(label: "TARGET DATE") {
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: $hasTargetDate) {
                    Text("Set target date")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                }
                .tint(Theme.accent)

                if hasTargetDate {
                    DatePicker("", selection: $targetDate, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(Theme.accent)
                        .colorScheme(.dark)
                }
            }
        }
    }

    private var statusCard: some View {
        field(label: "STATUS") {
            HStack(spacing: 8) {
                ForEach(GoalStatus.allCases.sorted { $0.sortIndex < $1.sortIndex }) { option in
                    statusButton(option)
                }
            }
        }
    }

    private func statusButton(_ option: GoalStatus) -> some View {
        let isSelected = status == option
        return Button { status = option } label: {
            VStack(spacing: 6) {
                Image(systemName: option.systemImage)
                    .font(.system(size: 14, weight: .bold))
                Text(option.rawValue.uppercased())
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(0.8)
            }
            .foregroundColor(isSelected ? Theme.background : Theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Theme.accent : Theme.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Theme.accent : Theme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var detailsCard: some View {
        field(label: "NOTES") {
            ZStack(alignment: .topLeading) {
                if details.isEmpty {
                    Text("Why does this matter? What does success look like?")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.textTertiary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $details)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100)
            }
        }
    }

    @ViewBuilder
    private func field<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
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
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true
        if case .edit(let goal) = mode {
            title = goal.title
            details = goal.details
            targetValue = goal.targetValue
            status = goal.status
            if let date = goal.targetDate {
                targetDate = date
                hasTargetDate = true
            }
        }
    }

    private func save() {
        let draft = GoalDraft(
            title: title.trimmingCharacters(in: .whitespaces),
            details: details,
            targetValue: targetValue.trimmingCharacters(in: .whitespaces),
            targetDate: hasTargetDate ? targetDate : nil,
            status: status
        )
        onSave(draft)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        PitGoalsView()
    }
    .modelContainer(for: [PitGoal.self], inMemory: true)
    .preferredColorScheme(.dark)
}
