//
//  PitNoteEditorView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

private enum NoteEditorField: Hashable {
    case title
    case body
}

struct PitNoteEditorView: View {
    @Environment(\.modelContext) private var modelContext
    let note: PitNote

    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var didLoad: Bool = false
    @FocusState private var focusedField: NoteEditorField?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
                .dismissKeyboardOnTap()

            ScrollView {
                VStack(spacing: 18) {
                    titleCard
                    bodyCard
                }
                .padding(20)
            }
        }
        .navigationTitle("Note")
        .navigationBarTitleDisplayMode(.inline)
        .keyboardToolbar(focusedField: $focusedField, fields: [.title, .body])
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            title = note.title
            bodyText = note.bodyText
        }
        .onDisappear { persistOrDelete() }
    }

    private var titleCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TITLE")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.8)
                .foregroundColor(Theme.accent)
            TextField(
                "",
                text: $title,
                prompt: Text("Untitled note").foregroundColor(Theme.textTertiary)
            )
            .font(.system(size: 20, weight: .heavy))
            .foregroundColor(Theme.textPrimary)
            .textInputAutocapitalization(.sentences)
            .autocorrectionDisabled()
            .focused($focusedField, equals: .title)
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

    private var bodyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BODY")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.8)
                .foregroundColor(Theme.accent)
            ZStack(alignment: .topLeading) {
                if bodyText.isEmpty {
                    Text("Thoughts, setup notes, feedback…")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.textTertiary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $bodyText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 280)
                    .focused($focusedField, equals: .body)
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

    private func persistOrDelete() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty && trimmedBody.isEmpty {
            modelContext.delete(note)
            return
        }
        note.title = trimmedTitle
        note.bodyText = bodyText
        note.updatedAt = .now
    }
}

#Preview {
    NavigationStack {
        PitNoteEditorView(note: PitNote(title: "Silverstone setup", bodyText: "Try lower front ride height."))
    }
    .modelContainer(for: [PitNote.self], inMemory: true)
    .preferredColorScheme(.dark)
}
