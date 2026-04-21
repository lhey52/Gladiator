//
//  ExportShareView.swift
//  Gladiator
//

import SwiftUI
import SwiftData

struct ExportShareView: View {
    @ObservedObject private var iap = IAPManager.shared
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Session.date, order: .reverse)])
    private var sessions: [Session]
    @Query(sort: [SortDescriptor(\CustomField.sortOrder)])
    private var fields: [CustomField]
    @Query(sort: [SortDescriptor(\Track.name)])
    private var tracks: [Track]

    @State private var showingPaywall: Bool = false
    @State private var isExporting: Bool = false
    @State private var exportURL: URL?
    @State private var showingShareSheet: Bool = false
    @State private var exportErrorMessage: String?
    @State private var showingExportError: Bool = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: iap.isProUser ? "square.and.arrow.up.circle.fill" : "lock.circle.fill")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(Theme.accent)

                VStack(spacing: 8) {
                    Text(iap.isProUser ? "SHARE YOUR DATA" : "UNLOCK PRO TO EXPORT DATA")
                        .font(.system(size: 16, weight: .heavy))
                        .tracking(2)
                        .foregroundColor(Theme.textPrimary)
                    Text(iap.isProUser
                         ? "Export all sessions, metrics, and tracks as a .gladiator file to share with another device"
                         : "Upgrade to Gladiator Pro to export and share your racing data")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                if iap.isProUser {
                    Button {
                        startExport()
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
                } else {
                    Button { showingPaywall = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("Unlock Pro")
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
                }

                Text("\(sessions.count) sessions · \(fields.count) metrics · \(tracks.count) tracks")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Theme.textTertiary)

                Spacer()
            }

            if isExporting {
                Color.black.opacity(0.5).ignoresSafeArea()
                ProgressView()
                    .tint(Theme.accent)
                    .scaleEffect(1.5)
            }
        }
        .navigationTitle("Export & Share")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showingPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportURL {
                ActivityView(items: [url])
            }
        }
        .alert("Export Failed", isPresented: $showingExportError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(exportErrorMessage ?? "The export failed. Please try again.")
        }
    }

    private func startExport() {
        isExporting = true
        Task {
            do {
                let url = try GladiatorDataExport.writeExport(context: modelContext)
                exportURL = url
                isExporting = false
                showingShareSheet = true
            } catch {
                exportErrorMessage = "The export failed. \(error.localizedDescription)"
                isExporting = false
                showingExportError = true
            }
        }
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

#Preview {
    NavigationStack {
        ExportShareView()
    }
    .modelContainer(for: [Session.self, CustomField.self, FieldValue.self, Track.self], inMemory: true)
    .preferredColorScheme(.dark)
}
