//
//  PitNotesView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct PitNotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\PitNote.updatedAt, order: .reverse)])
    private var notes: [PitNote]

    @State private var selectedNote: PitNote?
    @State private var noteToDelete: PitNote?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            content
        }
        .navigationTitle("Quick Notes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { createNote() } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.accent)
                }
            }
        }
        .navigationDestination(item: $selectedNote) { note in
            PitNoteEditorView(note: note)
        }
        .alert(
            "Delete Note",
            isPresented: Binding(
                get: { noteToDelete != nil },
                set: { if !$0 { noteToDelete = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) { noteToDelete = nil }
            Button("Delete", role: .destructive) {
                if let note = noteToDelete {
                    modelContext.delete(note)
                    noteToDelete = nil
                }
            }
        } message: {
            Text("This note will be permanently deleted.")
        }
    }

    @ViewBuilder
    private var content: some View {
        if notes.isEmpty {
            emptyState
        } else {
            list
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "note.text")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.8))
            Text("NO NOTES YET")
                .font(.system(size: 16, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.textPrimary)
            Text("Tap + to jot down setup thoughts, feedback, or anything else")
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
                ForEach(Array(notes.enumerated()), id: \.element.id) { index, note in
                    Button { selectedNote = note } label: {
                        NoteRow(note: note)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button(role: .destructive) {
                            noteToDelete = note
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }

                    if index < notes.count - 1 {
                        Divider().background(Theme.hairline).padding(.leading, 14)
                    }
                }
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(20)
        }
    }

    private func createNote() {
        let note = PitNote()
        modelContext.insert(note)
        selectedNote = note
    }
}

private struct NoteRow: View {
    let note: PitNote

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM dd, yyyy"
        return f
    }()

    private var displayTitle: String {
        note.title.trimmingCharacters(in: .whitespaces).isEmpty ? "Untitled" : note.title
    }

    private var preview: String {
        let trimmed = note.bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "No content" : trimmed
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(displayTitle)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                Text(preview)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(2)
                Text(Self.dateFormatter.string(from: note.updatedAt).uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(Theme.textTertiary)
                    .padding(.top, 2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(14)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        PitNotesView()
    }
    .modelContainer(for: [PitNote.self], inMemory: true)
    .preferredColorScheme(.dark)
}
