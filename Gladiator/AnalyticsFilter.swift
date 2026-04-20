//
//  AnalyticsFilter.swift
//  Gladiator
//

import SwiftUI
import SwiftData

@Observable
final class AnalyticsFilterState {
    var selectedTracks: Set<String> = []
    var startDate: Date?
    var endDate: Date?

    var isActive: Bool {
        !selectedTracks.isEmpty || startDate != nil || endDate != nil
    }

    func apply(to sessions: [Session]) -> [Session] {
        sessions.filter { session in
            if !selectedTracks.isEmpty, !selectedTracks.contains(session.trackName) {
                return false
            }
            if let start = startDate, session.date < start {
                return false
            }
            if let end = endDate, session.date > Calendar.current.date(byAdding: .day, value: 1, to: end) ?? end {
                return false
            }
            return true
        }
    }

    func reset() {
        selectedTracks.removeAll()
        startDate = nil
        endDate = nil
    }
}

struct FilterButton: View {
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
                if isActive {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: -2)
                }
            }
        }
    }
}

struct FilterSheetView: View {
    @Bindable var filter: AnalyticsFilterState
    @Query(sort: [SortDescriptor(\Track.name)])
    private var tracks: [Track]
    @Environment(\.dismiss) private var dismiss

    @State private var localTracks: Set<String> = []
    @State private var localStartDate: Date = Calendar.current.date(byAdding: .year, value: -1, to: .now) ?? .now
    @State private var localEndDate: Date = .now
    @State private var dateFilterEnabled: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                formContent
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
        .preferredColorScheme(.dark)
        .onAppear { loadState() }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Reset") {
                localTracks.removeAll()
                dateFilterEnabled = false
            }
            .font(.system(size: 15, weight: .heavy))
            .foregroundColor(Theme.accent)
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Done") { applyAndDismiss() }
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(Theme.accent)
        }
    }

    private var formContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                trackSection
                dateSection
            }
            .padding(20)
        }
    }

    private var trackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TRACKS")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.8)
                .foregroundColor(Theme.accent)
                .padding(.leading, 4)

            if tracks.isEmpty {
                Text("No tracks saved")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textTertiary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface)
                    )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                        Button {
                            if localTracks.contains(track.name) {
                                localTracks.remove(track.name)
                            } else {
                                localTracks.insert(track.name)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                let selected = localTracks.contains(track.name)
                                ZStack {
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .stroke(selected ? Theme.accent : Theme.textTertiary, lineWidth: 1.5)
                                        .frame(width: 20, height: 20)
                                    if selected {
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .fill(Theme.accent)
                                            .frame(width: 20, height: 20)
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Theme.background)
                                    }
                                }
                                Text(track.name)
                                    .font(.system(size: 15, weight: .heavy))
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index < tracks.count - 1 {
                            Divider().background(Theme.hairline).padding(.leading, 46)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface)
                )
            }
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DATE RANGE")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.8)
                    .foregroundColor(Theme.accent)
                Spacer()
                Toggle("", isOn: $dateFilterEnabled)
                    .labelsHidden()
                    .tint(Theme.accent)
            }
            .padding(.horizontal, 4)

            if dateFilterEnabled {
                VStack(spacing: 0) {
                    HStack {
                        Text("FROM")
                            .font(.system(size: 11, weight: .heavy))
                            .tracking(1)
                            .foregroundColor(Theme.textSecondary)
                        Spacer()
                        DatePicker("", selection: $localStartDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(Theme.accent)
                            .colorScheme(.dark)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)

                    Divider().background(Theme.hairline).padding(.leading, 14)

                    HStack {
                        Text("TO")
                            .font(.system(size: 11, weight: .heavy))
                            .tracking(1)
                            .foregroundColor(Theme.textSecondary)
                        Spacer()
                        DatePicker("", selection: $localEndDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(Theme.accent)
                            .colorScheme(.dark)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface)
                )
            }
        }
    }

    private func loadState() {
        localTracks = filter.selectedTracks
        if let start = filter.startDate {
            localStartDate = start
            dateFilterEnabled = true
        }
        if let end = filter.endDate {
            localEndDate = end
            dateFilterEnabled = true
        }
    }

    private func applyAndDismiss() {
        filter.selectedTracks = localTracks
        if dateFilterEnabled {
            filter.startDate = localStartDate
            filter.endDate = localEndDate
        } else {
            filter.startDate = nil
            filter.endDate = nil
        }
        dismiss()
    }
}
