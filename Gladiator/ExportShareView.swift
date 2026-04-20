//
//  ExportShareView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct ExportShareView: View {
    @Query(sort: [SortDescriptor(\Session.date, order: .reverse)])
    private var sessions: [Session]
    @Query(sort: [SortDescriptor(\CustomField.sortOrder)])
    private var fields: [CustomField]
    @Query(sort: [SortDescriptor(\Track.name)])
    private var tracks: [Track]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(Theme.accent)

                VStack(spacing: 8) {
                    Text("SHARE YOUR DATA")
                        .font(.system(size: 16, weight: .heavy))
                        .tracking(2)
                        .foregroundColor(Theme.textPrimary)
                    Text("Export all sessions, metrics, and tracks as a .gladiator file to share with another device")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Button {
                    // Export functionality coming soon
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.up.doc.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("Share Data with Another Gladiator App")
                            .font(.system(size: 14, weight: .heavy))
                    }
                    .foregroundColor(Theme.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Theme.accent)
                    )
                    .shadow(color: Theme.accent.opacity(0.4), radius: 12)
                }
                .padding(.horizontal, 32)

                Text("\(sessions.count) sessions · \(fields.count) metrics · \(tracks.count) tracks")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.textTertiary)

                Spacer()
            }
        }
        .navigationTitle("Export & Share")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ExportShareView()
    }
    .modelContainer(for: [Session.self, CustomField.self, FieldValue.self, Track.self], inMemory: true)
    .preferredColorScheme(.dark)
}
