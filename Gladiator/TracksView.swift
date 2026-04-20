//
//  TracksView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct TracksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Track.name)])
    private var tracks: [Track]

    @State private var showingAdd: Bool = false
    @State private var newTrackName: String = ""
    @State private var trackToEdit: Track?
    @State private var editName: String = ""
    @State private var trackToDelete: Track?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            content
        }
        .navigationTitle("Tracks")
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
        .alert("New Track", isPresented: $showingAdd) {
            TextField("Track name", text: $newTrackName)
            Button("Cancel", role: .cancel) { newTrackName = "" }
            Button("Add") { addTrack() }
        }
        .alert("Edit Track", isPresented: Binding(
            get: { trackToEdit != nil },
            set: { if !$0 { trackToEdit = nil } }
        )) {
            TextField("Track name", text: $editName)
            Button("Cancel", role: .cancel) { trackToEdit = nil }
            Button("Save") { saveEdit() }
        }
        .alert("Delete Track", isPresented: Binding(
            get: { trackToDelete != nil },
            set: { if !$0 { trackToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { trackToDelete = nil }
            Button("Delete", role: .destructive) { confirmDelete() }
        } message: {
            if let track = trackToDelete {
                Text("Are you sure you want to delete \"\(track.name)\"?")
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if tracks.isEmpty {
            emptyState
        } else {
            trackList
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.8))
            Text("NO TRACKS")
                .font(.system(size: 16, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.textPrimary)
            Text("Add tracks to quickly select them when logging sessions")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var trackList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                    trackRow(track)

                    if index < tracks.count - 1 {
                        Divider()
                            .background(Theme.hairline)
                            .padding(.leading, 14)
                    }
                }
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 20)
            .padding(.top, 4)

            Text("Tap a track to set or remove it as default. The default track is pre-selected in new sessions.")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
        }
    }

    private func trackRow(_ track: Track) -> some View {
        HStack(spacing: 12) {
            Button {
                toggleDefault(track)
            } label: {
                HStack(spacing: 12) {
                    if track.isDefault {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Theme.accent)
                    } else {
                        Circle()
                            .stroke(Theme.textTertiary, lineWidth: 1.5)
                            .frame(width: 18, height: 18)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.name)
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(Theme.textPrimary)
                        if track.isDefault {
                            Text("DEFAULT")
                                .font(.system(size: 9, weight: .heavy))
                                .tracking(1.2)
                                .foregroundColor(Theme.accent)
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Menu {
                Button {
                    editName = track.name
                    trackToEdit = track
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    trackToDelete = track
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
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func addTrack() {
        let trimmed = newTrackName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { newTrackName = ""; return }
        let track = Track(name: trimmed)
        modelContext.insert(track)
        newTrackName = ""
    }

    private func saveEdit() {
        guard let track = trackToEdit else { return }
        let trimmed = editName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { trackToEdit = nil; return }
        track.name = trimmed
        trackToEdit = nil
    }

    private func confirmDelete() {
        guard let track = trackToDelete else { return }
        modelContext.delete(track)
        trackToDelete = nil
    }

    private func toggleDefault(_ track: Track) {
        if track.isDefault {
            track.isDefault = false
        } else {
            for t in tracks { t.isDefault = false }
            track.isDefault = true
        }
    }
}

#Preview {
    NavigationStack {
        TracksView()
    }
    .modelContainer(for: [Track.self], inMemory: true)
    .preferredColorScheme(.dark)
}
