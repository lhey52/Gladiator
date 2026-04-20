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
    @State private var isEditing: Bool = false
    @State private var selectedIDs: Set<PersistentIdentifier> = []
    @State private var showingDeleteConfirm: Bool = false
    @State private var sessionCountBeforeSheet: Int = 0
    @State private var toastIcon: String = ""
    @State private var toastText: String = ""
    @State private var showToast: Bool = false
    @State private var showingPaywall: Bool = false
    @ObservedObject private var iap = IAPManager.shared
    @FocusState private var searchFocused: Bool

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
                    .dismissKeyboardOnTap()

                VStack(spacing: 0) {
                    searchBar
                    filterBar
                    content
                    limitBanner
                }

                if showToast {
                    VStack {
                        Spacer()
                        ToastView(icon: toastIcon, text: toastText)
                            .transition(.opacity)
                            .padding(.bottom, 16)
                    }
                    .allowsHitTesting(false)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: showToast)
            .navigationTitle("Sessions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if isEditing {
                            isEditing = false
                            selectedIDs.removeAll()
                        } else {
                            isEditing = true
                        }
                    } label: {
                        Text(isEditing ? "Done" : "Edit")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(Theme.accent)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    if isEditing {
                        Button {
                            showingDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(selectedIDs.isEmpty ? Theme.textTertiary : Theme.accent)
                        }
                        .disabled(selectedIDs.isEmpty)
                    } else {
                        Button {
                            if iap.checkSessionLimit(currentCount: sessions.count) {
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
            }
            .confirmationDialog(
                "Delete \(selectedIDs.count) session\(selectedIDs.count == 1 ? "" : "s")?",
                isPresented: $showingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteSelected()
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showingAdd, onDismiss: {
                if sessions.count > sessionCountBeforeSheet {
                    showToastBriefly(icon: "checkmark.circle.fill", text: "Session Saved")
                }
            }) {
                AddSessionView()
            }
            .onChange(of: showingAdd) {
                if showingAdd { sessionCountBeforeSheet = sessions.count }
            }
            .onChange(of: sessions.count) { oldCount, newCount in
                if newCount < oldCount, !isEditing {
                    let deleted = oldCount - newCount
                    showToastBriefly(
                        icon: "trash",
                        text: deleted == 1 ? "Session Deleted" : "\(deleted) Sessions Deleted"
                    )
                }
            }
            .fullScreenCover(isPresented: $showingPaywall) {
                PaywallView(limitMessage: "You have reached the free limit of \(IAPManager.sessionLimit) sessions. Upgrade to Pro for unlimited sessions.")
            }
        }
    }

    @ViewBuilder
    private var limitBanner: some View {
        if iap.isAtSessionLimit(currentCount: sessions.count) {
            Button { showingPaywall = true } label: {
                HStack(spacing: 8) {
                    Text("You've reached the free limit. Upgrade to Pro for unlimited sessions.")
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
                .focused($searchFocused)
                .submitLabel(.done)
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
                VStack(spacing: 0) {
                    ForEach(Array(filteredSessions.enumerated()), id: \.element.id) { index, session in
                        if isEditing {
                            Button {
                                toggleSelection(session)
                            } label: {
                                HStack(spacing: 0) {
                                    selectionCircle(for: session)
                                        .padding(.leading, 14)
                                    SessionRow(session: session)
                                }
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink {
                                SessionDetailView(session: session)
                            } label: {
                                SessionRow(session: session)
                            }
                            .buttonStyle(.plain)
                        }

                        if index < filteredSessions.count - 1 {
                            Divider()
                                .background(Theme.hairline)
                                .padding(.leading, isEditing ? 90 : 56)
                        }
                    }
                }
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }

    private func selectionCircle(for session: Session) -> some View {
        let selected = selectedIDs.contains(session.persistentModelID)
        return ZStack {
            Circle()
                .stroke(selected ? Theme.accent : Theme.textTertiary, lineWidth: 2)
                .frame(width: 24, height: 24)
            if selected {
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 24, height: 24)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.background)
            }
        }
        .animation(.easeOut(duration: 0.15), value: selected)
    }

    private func toggleSelection(_ session: Session) {
        let id = session.persistentModelID
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    private func deleteSelected() {
        let count = selectedIDs.count
        for session in sessions where selectedIDs.contains(session.persistentModelID) {
            modelContext.delete(session)
        }
        selectedIDs.removeAll()
        isEditing = false
        showToastBriefly(
            icon: "trash",
            text: count == 1 ? "Session Deleted" : "\(count) Sessions Deleted"
        )
    }

    private func showToastBriefly(icon: String, text: String) {
        toastIcon = icon
        toastText = text
        showToast = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            showToast = false
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
        f.dateFormat = "MMM dd, yyyy"
        return f
    }()

    private var accentBarColor: Color {
        switch session.sessionType {
        case .race: return Theme.accent
        case .qualifying: return Theme.accent.opacity(0.65)
        case .practice: return Theme.accent.opacity(0.35)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(accentBarColor)
                .frame(width: 3, height: 32)
                .padding(.leading, 14)
                .padding(.trailing, 12)

            VStack(alignment: .leading, spacing: 3) {
                Text(session.trackName.isEmpty ? "Untitled Track" : session.trackName)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 5) {
                    Image(systemName: session.sessionType.systemImage)
                        .font(.system(size: 9, weight: .bold))
                    Text(session.sessionType.rawValue.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                    Text("·")
                    Text(Self.dateFormatter.string(from: session.date).uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.8)
                }
                .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.textTertiary)
                .padding(.trailing, 14)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

#Preview {
    SessionsView()
        .modelContainer(for: Session.self, inMemory: true)
        .preferredColorScheme(.dark)
}
