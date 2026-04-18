//
//  SessionPickerView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct SessionPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\Session.date, order: .reverse)])
    private var sessions: [Session]

    let title: String
    let onSelect: (Session) -> Void

    @State private var searchText: String = ""

    private var filtered: [Session] {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return sessions }
        return sessions.filter {
            $0.trackName.localizedCaseInsensitiveContains(trimmed)
            || $0.sessionType.rawValue.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM dd, yyyy · HH:mm"
        return f
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar
                    sessionList
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.textSecondary)
            TextField("", text: $searchText, prompt: Text("Search sessions").foregroundColor(Theme.textTertiary))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var sessionList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filtered) { session in
                    Button {
                        onSelect(session)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(session.trackName.isEmpty ? "Untitled Track" : session.trackName)
                                    .font(.system(size: 15, weight: .heavy))
                                    .foregroundColor(Theme.textPrimary)
                                    .lineLimit(1)
                                HStack(spacing: 6) {
                                    Image(systemName: session.sessionType.systemImage)
                                        .font(.system(size: 9, weight: .bold))
                                    Text(session.sessionType.rawValue.uppercased())
                                        .font(.system(size: 10, weight: .bold))
                                        .tracking(1)
                                    Text("·")
                                        .foregroundColor(Theme.textTertiary)
                                    Text(Self.dateFormatter.string(from: session.date))
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .foregroundColor(Theme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Theme.textTertiary)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Theme.hairline, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

#Preview {
    SessionPickerView(title: "Select Session A") { _ in }
        .modelContainer(for: [Session.self, CustomField.self, FieldValue.self], inMemory: true)
}
