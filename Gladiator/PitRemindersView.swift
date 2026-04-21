//
//  PitRemindersView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct PitRemindersView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\PitReminder.dueDate, order: .forward)])
    private var reminders: [PitReminder]

    @State private var reminderToEdit: PitReminder?
    @State private var reminderToDelete: PitReminder?
    @State private var showingNewReminder: Bool = false
    @AppStorage("reminderShowCompleted") private var showCompleted: Bool = true

    private var activeReminders: [PitReminder] {
        reminders.filter { !$0.isCompleted }
    }

    private var completedReminders: [PitReminder] {
        reminders.filter { $0.isCompleted }.sorted { $0.dueDate > $1.dueDate }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            content
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingNewReminder = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.accent)
                }
            }
        }
        .sheet(isPresented: $showingNewReminder) {
            ReminderEditorSheet(mode: .create) { draft in
                createReminder(from: draft)
            }
        }
        .sheet(item: $reminderToEdit) { reminder in
            ReminderEditorSheet(mode: .edit(reminder)) { draft in
                applyEdit(draft, to: reminder)
            }
        }
        .alert(
            "Delete Reminder",
            isPresented: Binding(
                get: { reminderToDelete != nil },
                set: { if !$0 { reminderToDelete = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) { reminderToDelete = nil }
            Button("Delete", role: .destructive) {
                if let reminder = reminderToDelete {
                    ReminderNotifications.cancel(id: reminder.notificationID)
                    modelContext.delete(reminder)
                    reminderToDelete = nil
                }
            }
        } message: {
            Text("This reminder will be permanently deleted.")
        }
    }

    @ViewBuilder
    private var content: some View {
        if reminders.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(spacing: 20) {
                    if !activeReminders.isEmpty {
                        activeSection
                    }
                    if !completedReminders.isEmpty {
                        completedSection
                    }
                }
                .padding(20)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "bell.slash")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.8))
            Text("NO REMINDERS")
                .font(.system(size: 16, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.textPrimary)
            Text("Schedule reminders for tire changes, license renewals, race weekends — anything with a deadline")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var activeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("UPCOMING")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.8)
                    .foregroundColor(Theme.accent)
                Text("(\(activeReminders.count))")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
                Spacer()
            }
            .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(activeReminders.enumerated()), id: \.element.id) { index, reminder in
                    Button { reminderToEdit = reminder } label: {
                        reminderRow(reminder)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button { complete(reminder) } label: {
                            Label("Complete", systemImage: "checkmark.circle.fill")
                        }
                        .tint(Theme.accent)
                        Button(role: .destructive) {
                            reminderToDelete = reminder
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    if index < activeReminders.count - 1 {
                        Divider().background(Theme.hairline).padding(.leading, 14)
                    }
                }
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button { showCompleted.toggle() } label: {
                HStack(spacing: 8) {
                    Text("COMPLETED")
                        .font(.system(size: 10, weight: .heavy))
                        .tracking(1.8)
                        .foregroundColor(Theme.textSecondary)
                    Text("(\(completedReminders.count))")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.textTertiary)
                    Spacer()
                    Image(systemName: showCompleted ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.textTertiary)
                }
                .padding(.horizontal, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showCompleted {
                VStack(spacing: 0) {
                    ForEach(Array(completedReminders.enumerated()), id: \.element.id) { index, reminder in
                        Button { reminderToEdit = reminder } label: {
                            reminderRow(reminder)
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button { uncomplete(reminder) } label: {
                                Label("Restore", systemImage: "arrow.uturn.backward")
                            }
                            .tint(Theme.accent)
                            Button(role: .destructive) {
                                reminderToDelete = reminder
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        if index < completedReminders.count - 1 {
                            Divider().background(Theme.hairline).padding(.leading, 14)
                        }
                    }
                }
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private func reminderRow(_ reminder: PitReminder) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(reminder.isCompleted ? Theme.accent : (reminder.isOverdue ? Color.red : Theme.textTertiary), lineWidth: 2)
                    .frame(width: 22, height: 22)
                if reminder.isCompleted {
                    Circle().fill(Theme.accent).frame(width: 22, height: 22)
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(Theme.background)
                }
            }
            .onTapGesture {
                if reminder.isCompleted {
                    uncomplete(reminder)
                } else {
                    complete(reminder)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title.isEmpty ? "Untitled reminder" : reminder.title)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(reminder.isCompleted ? Theme.textSecondary : Theme.textPrimary)
                    .strikethrough(reminder.isCompleted, color: Theme.textSecondary)
                    .lineLimit(1)
                HStack(spacing: 5) {
                    if reminder.isOverdue {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.red)
                    }
                    Text(Self.formatDueDate(reminder.dueDate).uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.8)
                        .foregroundColor(reminder.isOverdue ? .red : Theme.textSecondary)
                }
                if !reminder.note.isEmpty {
                    Text(reminder.note)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textTertiary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private static func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy · HH:mm"
        return formatter.string(from: date)
    }

    // MARK: - Actions

    private func createReminder(from draft: ReminderDraft) {
        let reminder = PitReminder(
            title: draft.title,
            note: draft.note,
            dueDate: draft.dueDate
        )
        modelContext.insert(reminder)
        Task {
            let granted = await ReminderNotifications.requestAuthorization()
            if granted {
                await ReminderNotifications.schedule(
                    id: reminder.notificationID,
                    title: reminder.title,
                    body: reminder.note,
                    at: reminder.dueDate
                )
            }
        }
    }

    private func applyEdit(_ draft: ReminderDraft, to reminder: PitReminder) {
        reminder.title = draft.title
        reminder.note = draft.note
        reminder.dueDate = draft.dueDate
        Task {
            let granted = await ReminderNotifications.requestAuthorization()
            if granted, !reminder.isCompleted {
                await ReminderNotifications.schedule(
                    id: reminder.notificationID,
                    title: reminder.title,
                    body: reminder.note,
                    at: reminder.dueDate
                )
            } else {
                ReminderNotifications.cancel(id: reminder.notificationID)
            }
        }
    }

    private func complete(_ reminder: PitReminder) {
        reminder.isCompleted = true
        ReminderNotifications.cancel(id: reminder.notificationID)
    }

    private func uncomplete(_ reminder: PitReminder) {
        reminder.isCompleted = false
        Task {
            let granted = await ReminderNotifications.requestAuthorization()
            if granted {
                await ReminderNotifications.schedule(
                    id: reminder.notificationID,
                    title: reminder.title,
                    body: reminder.note,
                    at: reminder.dueDate
                )
            }
        }
    }
}

// MARK: - Editor sheet

private struct ReminderDraft {
    var title: String
    var note: String
    var dueDate: Date
}

private enum ReminderEditorMode {
    case create
    case edit(PitReminder)

    var isCreate: Bool {
        if case .create = self { return true }
        return false
    }
}

private struct ReminderEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let mode: ReminderEditorMode
    let onSave: (ReminderDraft) -> Void

    @State private var title: String = ""
    @State private var note: String = ""
    @State private var dueDate: Date = .now.addingTimeInterval(3600)
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
                        dueCard
                        noteCard
                    }
                    .padding(20)
                }
            }
            .navigationTitle(mode.isCreate ? "New Reminder" : "Edit Reminder")
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
                prompt: Text("e.g. Book track day").foregroundColor(Theme.textTertiary)
            )
            .font(.system(size: 18, weight: .heavy))
            .foregroundColor(Theme.textPrimary)
            .textInputAutocapitalization(.sentences)
            .autocorrectionDisabled()
        }
    }

    private var dueCard: some View {
        field(label: "DUE") {
            DatePicker(
                "",
                selection: $dueDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .tint(Theme.accent)
            .colorScheme(.dark)
        }
    }

    private var noteCard: some View {
        field(label: "NOTE") {
            ZStack(alignment: .topLeading) {
                if note.isEmpty {
                    Text("Optional details")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.textTertiary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $note)
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
        if case .edit(let reminder) = mode {
            title = reminder.title
            note = reminder.note
            dueDate = reminder.dueDate
        }
    }

    private func save() {
        let draft = ReminderDraft(
            title: title.trimmingCharacters(in: .whitespaces),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            dueDate: dueDate
        )
        onSave(draft)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        PitRemindersView()
    }
    .modelContainer(for: [PitReminder.self], inMemory: true)
    .preferredColorScheme(.dark)
}
