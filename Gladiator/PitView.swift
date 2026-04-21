//
//  PitView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct PitView: View {
    @Query private var notes: [PitNote]
    @Query private var templates: [PitChecklistTemplate]
    @Query private var goals: [PitGoal]
    @Query private var reminders: [PitReminder]

    private var activeReminderCount: Int {
        reminders.filter { !$0.isCompleted }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        pitHeader
                        card(
                            title: "Checklists",
                            icon: "checklist",
                            summary: summary(count: templates.count, singular: "checklist", plural: "checklists"),
                            destination: PitChecklistsView()
                        )
                        card(
                            title: "Quick Notes",
                            icon: "note.text",
                            summary: summary(count: notes.count, singular: "note", plural: "notes"),
                            destination: PitNotesView()
                        )
                        card(
                            title: "Goals",
                            icon: "flag.2.crossed.fill",
                            summary: summary(count: goals.count, singular: "goal", plural: "goals"),
                            destination: PitGoalsView()
                        )
                        card(
                            title: "Reminders",
                            icon: "bell.badge.fill",
                            summary: summary(count: activeReminderCount, singular: "reminder", plural: "reminders"),
                            destination: PitRemindersView()
                        )
                    }
                    .padding(20)
                }
            }
            .navigationTitle("The Pit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Text("The Pit")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        ProBadgeIfNeeded()
                    }
                }
            }
        }
    }

    private var pitHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(Theme.accent)
            Text("PADDOCK WHITEBOARD")
                .font(.system(size: 11, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 2)
    }

    private func summary(count: Int, singular: String, plural: String) -> String {
        count == 0 ? "Nothing yet — tap to add" : "\(count) \(count == 1 ? singular : plural)"
    }

    private func card<Destination: View>(
        title: String,
        icon: String,
        summary: String,
        destination: Destination
    ) -> some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.accent.opacity(0.15))
                        .frame(width: 56, height: 56)
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.accent.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(Theme.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title.uppercased())
                        .font(.system(size: 16, weight: .heavy))
                        .tracking(1.2)
                        .foregroundColor(Theme.textPrimary)
                    Text(summary)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Theme.accent.opacity(0.25), lineWidth: 1.5)
            )
            .shadow(color: Theme.accent.opacity(0.1), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PitView()
        .modelContainer(for: [
            PitNote.self,
            PitChecklistTemplate.self,
            PitChecklistItem.self,
            PitGoal.self,
            PitReminder.self
        ], inMemory: true)
        .preferredColorScheme(.dark)
}
