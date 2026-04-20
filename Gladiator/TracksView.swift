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
    @State private var trackToEdit: Track?
    @State private var trackToDelete: Track?
    @State private var showingPaywall: Bool = false
    @ObservedObject private var iap = IAPManager.shared

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                content
                trackLimitBanner
            }
        }
        .navigationTitle("Tracks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if iap.checkTrackLimit(currentCount: tracks.count) {
                        showingAdd = true
                    } else {
                        showingPaywall = true
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.accent)
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            TrackFormSheet(
                title: "New Track",
                buttonLabel: "Add",
                initialName: "",
                existingNames: tracks.map(\.name),
                excludeName: nil
            ) { name in
                let track = Track(name: name)
                modelContext.insert(track)
            }
        }
        .sheet(item: $trackToEdit) { track in
            TrackFormSheet(
                title: "Edit Track",
                buttonLabel: "Save",
                initialName: track.name,
                existingNames: tracks.map(\.name),
                excludeName: track.name
            ) { newName in
                track.name = newName
            }
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
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView(limitMessage: "You have reached the free limit of \(IAPManager.trackLimit) tracks. Upgrade to Pro for unlimited tracks.")
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

    @ViewBuilder
    private var trackLimitBanner: some View {
        if iap.isAtTrackLimit(currentCount: tracks.count) {
            Button { showingPaywall = true } label: {
                HStack(spacing: 8) {
                    Text("You've reached the free limit. Upgrade to Pro for unlimited tracks.")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                    Text("Upgrade to Pro")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(Theme.accent)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Theme.surface)
                .overlay(
                    Rectangle().frame(height: 1).foregroundColor(Theme.hairline),
                    alignment: .top
                )
            }
            .buttonStyle(.plain)
        }
    }
}

private struct TrackFormSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let buttonLabel: String
    let initialName: String
    let existingNames: [String]
    let excludeName: String?
    let onSave: (String) -> Void

    @State private var name: String = ""

    private var trimmed: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    private var isDuplicate: Bool {
        guard !trimmed.isEmpty else { return false }
        let lower = trimmed.lowercased()
        return existingNames.contains { existing in
            let isExcluded = excludeName.map { $0.lowercased() == existing.lowercased() } ?? false
            return !isExcluded && existing.lowercased() == lower
        }
    }

    private var canSave: Bool {
        !trimmed.isEmpty && !isDuplicate
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                    .dismissKeyboardOnTap()
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("TRACK NAME")
                            .font(.system(size: 10, weight: .heavy))
                            .tracking(1.8)
                            .foregroundColor(Theme.accent)
                        TextField(
                            "",
                            text: $name,
                            prompt: Text("e.g. Silverstone GP").foregroundColor(Theme.textTertiary)
                        )
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(Theme.textPrimary)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        if isDuplicate {
                            Text("A track with this name already exists")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Theme.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Theme.hairline, lineWidth: 1)
                    )
                    .padding(20)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(buttonLabel) {
                        onSave(trimmed)
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(canSave ? Theme.accent : Theme.textTertiary)
                    .disabled(!canSave)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { name = initialName }
    }
}

#Preview {
    NavigationStack {
        TracksView()
    }
    .modelContainer(for: [Track.self], inMemory: true)
    .preferredColorScheme(.dark)
}
