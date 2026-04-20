//
//  SessionDetailView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let session: Session

    @State private var showingDeleteConfirm: Bool = false
    @State private var showingEdit: Bool = false
    @State private var showSavedToast: Bool = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    headerCard
                    metaCard
                    if !sortedFieldValues.isEmpty {
                        customFieldsCard
                    }
                    if !session.notes.trimmingCharacters(in: .whitespaces).isEmpty {
                        notesCard
                    }
                }
                .padding(20)
            }

            if showSavedToast {
                VStack {
                    Spacer()
                    ToastView(icon: "checkmark.circle.fill", text: "Session Saved")
                        .transition(.opacity)
                        .padding(.bottom, 16)
                }
                .allowsHitTesting(false)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showSavedToast)
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 16) {
                    Button { showingEdit = true } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Theme.accent)
                    }
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Theme.accent)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEdit, onDismiss: {
            showSavedToast = true
            Task {
                try? await Task.sleep(for: .seconds(2))
                showSavedToast = false
            }
        }) {
            EditSessionView(session: session)
        }
        .confirmationDialog(
            "Delete this session?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: deleteSession)
            Button("Cancel", role: .cancel) { }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(session.sessionType.rawValue.uppercased(), systemImage: session.sessionType.systemImage)
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(1.5)
                    .foregroundColor(Theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.accent.opacity(0.15))
                    .overlay(Capsule().stroke(Theme.accent.opacity(0.5), lineWidth: 1))
                    .clipShape(Capsule())
                Spacer()
            }
            Text(session.trackName.isEmpty ? "Untitled Track" : session.trackName)
                .font(.system(size: 32, weight: .heavy))
                .foregroundColor(Theme.textPrimary)
            Text(Self.dateFormatter.string(from: session.date))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.accent.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: Theme.accent.opacity(0.15), radius: 16)
    }

    private var metaCard: some View {
        VStack(spacing: 0) {
            detailRow(label: "TRACK", value: session.trackName.isEmpty ? "—" : session.trackName)
            Divider().background(Theme.hairline)
            detailRow(label: "TYPE", value: session.sessionType.rawValue)
            Divider().background(Theme.hairline)
            detailRow(label: "DATE", value: Self.dateFormatter.string(from: session.date))
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
        )
    }

    private var sortedFieldValues: [FieldValue] {
        session.fieldValues.sorted { $0.fieldName.localizedCompare($1.fieldName) == .orderedAscending }
    }

    private var customFieldsCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("CUSTOM DATA")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1.8)
                    .foregroundColor(Theme.accent)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            ForEach(Array(sortedFieldValues.enumerated()), id: \.element.id) { index, fv in
                if index > 0 {
                    Divider().background(Theme.hairline)
                }
                detailRow(label: fv.fieldName.uppercased(), value: displayValue(for: fv))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NOTES")
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.8)
                .foregroundColor(Theme.accent)
            Text(session.notes)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .heavy))
                .tracking(1.5)
                .foregroundColor(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func displayValue(for fv: FieldValue) -> String {
        if fv.fieldType == .time, let secs = Double(fv.value) {
            return TimeFormatting.secondsToDisplay(secs)
        }
        return fv.value
    }

    private func deleteSession() {
        modelContext.delete(session)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        SessionDetailView(
            session: Session(
                date: .now,
                trackName: "Silverstone GP",
                sessionType: .qualifying,
                notes: "Soft compound, track temp 28°C. Rear felt loose on T3."
            )
        )
    }
    .modelContainer(for: Session.self, inMemory: true)
    .preferredColorScheme(.dark)
}
