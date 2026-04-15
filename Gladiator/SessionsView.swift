//
//  SessionsView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct SessionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Session.date, order: .reverse)])
    private var sessions: [Session]

    @State private var searchText: String = ""
    @State private var typeFilter: SessionType? = nil
    @State private var showingAdd: Bool = false

    private var filteredSessions: [Session] {
        sessions.filter { session in
            if let typeFilter, session.sessionType != typeFilter {
                return false
            }
            let trimmed = searchText.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { return true }
            return session.trackName.localizedCaseInsensitiveContains(trimmed)
                || session.sessionType.rawValue.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar
                    filterBar
                    content
                }
            }
            .navigationTitle("Sessions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Theme.accent)
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddSessionView()
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.textSecondary)
            TextField("", text: $searchText, prompt: Text("Search track or type").foregroundColor(Theme.textTertiary))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.textTertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 12)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "ALL", isSelected: typeFilter == nil) {
                    typeFilter = nil
                }
                ForEach(SessionType.allCases) { type in
                    FilterChip(
                        title: type.rawValue.uppercased(),
                        isSelected: typeFilter == type
                    ) {
                        typeFilter = (typeFilter == type) ? nil : type
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var content: some View {
        if filteredSessions.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(filteredSessions) { session in
                        NavigationLink {
                            SessionDetailView(session: session)
                        } label: {
                            SessionRow(session: session)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: sessions.isEmpty ? "flag.checkered" : "magnifyingglass")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(Theme.accent.opacity(0.8))
            Text(sessions.isEmpty ? "NO SESSIONS YET" : "NO MATCHES")
                .font(.system(size: 16, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.textPrimary)
            Text(sessions.isEmpty ? "Tap + to log your first session" : "Try a different search or filter")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(isSelected ? Theme.background : Theme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Theme.accent : Theme.surface)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Theme.accent : Theme.hairline, lineWidth: 1)
                )
                .shadow(color: isSelected ? Theme.accent.opacity(0.4) : .clear, radius: 8)
        }
        .buttonStyle(.plain)
    }
}

private struct SessionRow: View {
    let session: Session

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM dd"
        return f
    }()

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text(Self.dateFormatter.string(from: session.date).uppercased())
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.accent)
            }
            .frame(width: 52)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Theme.accent.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Theme.accent.opacity(0.4), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(session.trackName.isEmpty ? "Untitled Track" : session.trackName)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Image(systemName: session.sessionType.systemImage)
                        .font(.system(size: 10, weight: .bold))
                    Text(session.sessionType.rawValue.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.2)
                }
                .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }
}

#Preview {
    SessionsView()
        .modelContainer(for: Session.self, inMemory: true)
        .preferredColorScheme(.dark)
}
